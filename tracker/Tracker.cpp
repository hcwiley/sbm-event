#include "opencv2/video/tracking.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/imgproc/imgproc.hpp"


#include <time.h>
#include <ctype.h>
#include <iostream>
//#include <stdlib.h>
#include <stdio.h>
//#include <cstdio>
//#include <cmath>


#define ESC_KEY 27
#define T_KEY 116
#define SAPCE_BAR 32


using namespace std;
//using namespace cv;

// Forwards
//void Filter ( IplImage * img );
//void Find ( IplImage * src, IplImage * img );

//
// Global variables
int		width = 1;
int		height = 1;
CvFont	_idFont;

// various tracking parameters (in seconds)
const double MHI_DURATION = 1;
const double MAX_TIME_DELTA = 0.5;
const double MIN_TIME_DELTA = 0.05;
// number of cyclic frame buffer used for motion detection
// (should, probably, depend on FPS)
const int N = 4;

// ring image buffer
IplImage **buf = 0;
int last = 0;

// temporary images
IplImage *mhi = 0; // MHI
IplImage *orient = 0; // orientation
IplImage *mask = 0; // valid orientation mask
IplImage *segmask = 0; // motion segmentation map
CvMemStorage* storage = 0; // temporary storage

// parameters:
//  img - input video frame
//  dst - resultant motion picture
//  args - optional parameters
static void  update_mhi( cv::Mat imgMat, IplImage * dst, int diff_threshold )
{
    IplImage * img = cvCreateImage ( cvSize ( width, height ), IPL_DEPTH_8U, 1 );
    *img = imgMat;

    double timestamp = (double)clock()/CLOCKS_PER_SEC; // get current time in seconds
    CvSize size = cvSize(img->width,img->height); // get current frame size
    int i, idx1 = last, idx2;
    IplImage* silh;
    CvSeq* seq;
    CvRect comp_rect;
    double count;
    double angle;
    CvPoint center;
    double magnitude;
    CvScalar color;

    // allocate images at the beginning or
    // reallocate them if the frame size is changed
    if( !mhi || mhi->width != size.width || mhi->height != size.height ) {
        if( buf == 0 ) {
            buf = (IplImage**)malloc(N*sizeof(buf[0]));
            memset( buf, 0, N*sizeof(buf[0]));
        }

        for( i = 0; i < N; i++ ) {
            cvReleaseImage( &buf[i] );
            buf[i] = cvCreateImage( size, IPL_DEPTH_8U, 1 );
            cvZero( buf[i] );
        }
        cvReleaseImage( &mhi );
        cvReleaseImage( &orient );
        cvReleaseImage( &segmask );
        cvReleaseImage( &mask );

        mhi = cvCreateImage( size, IPL_DEPTH_32F, 1 );
        cvZero( mhi ); // clear MHI at the beginning
        orient = cvCreateImage( size, IPL_DEPTH_32F, 1 );
        segmask = cvCreateImage( size, IPL_DEPTH_32F, 1 );
        mask = cvCreateImage( size, IPL_DEPTH_8U, 1 );
    }

    //cv::cvtColor( imgMat, buf[last], CV_BGR2GRAY ); // convert frame to grayscale

    idx2 = (last + 1) % N; // index of (last - (N-1))th frame
    last = idx2;

    silh = buf[idx2];
    cvAbsDiff( buf[idx1], buf[idx2], silh ); // get difference between frames

    cv::Mat silhMat = imgMat.clone();
    cv::threshold( silhMat, silhMat, diff_threshold, 1, CV_THRESH_BINARY ); // and threshold it
    *silh = silhMat;
    cvUpdateMotionHistory( silh, mhi, timestamp, MHI_DURATION ); // update MHI

    // convert MHI to blue 8u image
    cvCvtScale( mhi, mask, 255./MHI_DURATION,
                (MHI_DURATION - timestamp)*255./MHI_DURATION );
    cvZero( dst );
    cvMerge( mask, 0, 0, 0, dst );

    // calculate motion gradient orientation and valid orientation mask
    cvCalcMotionGradient( mhi, mask, orient, MAX_TIME_DELTA, MIN_TIME_DELTA, 3 );

    if( !storage )
        storage = cvCreateMemStorage(0);
    else
        cvClearMemStorage(storage);

    // segment motion: get sequence of motion components
    // segmask is marked motion components map. It is not used further
    seq = cvSegmentMotion( mhi, segmask, storage, timestamp, MAX_TIME_DELTA );

    // iterate through the motion components,
    // One more iteration (i == -1) corresponds to the whole image (global motion)
    for( i = -1; i < seq->total; i++ ) {

        if( i < 0 ) { // case of the whole image
            comp_rect = cvRect( 0, 0, size.width, size.height );
            color = CV_RGB(255,255,255);
            magnitude = 100;
        }
        else { // i-th motion component
            comp_rect = ((CvConnectedComp*)cvGetSeqElem( seq, i ))->rect;
            if( comp_rect.width + comp_rect.height < 100 ) // reject very small components
                continue;
            color = CV_RGB(255,0,0);
            magnitude = 30;
        }

        // select component ROI
        cvSetImageROI( silh, comp_rect );
        cvSetImageROI( mhi, comp_rect );
        cvSetImageROI( orient, comp_rect );
        cvSetImageROI( mask, comp_rect );

        // calculate orientation
        angle = cvCalcGlobalOrientation( orient, mask, mhi, timestamp, MHI_DURATION);
        angle = 360.0 - angle;  // adjust for images with top-left origin

        count = cvNorm( silh, 0, CV_L1, 0 ); // calculate number of points within silhouette ROI

        cvResetImageROI( mhi );
        cvResetImageROI( orient );
        cvResetImageROI( mask );
        cvResetImageROI( silh );

        // check for the case of little motion
        if( count < comp_rect.width*comp_rect.height * 0.05 )
            continue;

        // draw a clock with arrow indicating the direction
        center = cvPoint( (comp_rect.x + comp_rect.width/2),
                          (comp_rect.y + comp_rect.height/2) );

        cvCircle( dst, center, cvRound(magnitude*1.2), color, 3, CV_AA, 0 );
        cvLine( dst, center, cvPoint( cvRound( center.x + magnitude*cos(angle*CV_PI/180)),
                cvRound( center.y - magnitude*sin(angle*CV_PI/180))), color, 3, CV_AA, 0 );
    }
}



int main( int argc, const char** argv )
{
  CvCapture* capture = 0;
  cv::Mat frame, frameCopy, image, grayMat, differenceMat;//edgesMat;
  cv::Mat templateMat, mhiMat;

  IplImage	*	img		= NULL;
  IplImage	*	gray	= NULL;
  //IplImage	*	edges	= NULL;
  IplImage	*	difference = NULL;
  IplImage	*	templateImg = NULL;
  IplImage	*	orient = NULL;
  IplImage	*	mhi= NULL;
  float			angle	= 0.0;

  bool run = true;

  // Initialize the Font used to draw into the source image
  cvInitFont ( &_idFont, CV_FONT_VECTOR0, 0.5, 0.5, 0.0, 1 );



  capture = cvCaptureFromCAM( 0 ); //0=default, -1=any camera, 1..99=your camera
  if(!capture) cout << "No camera detected" << endl;

  width	= (int) cvGetCaptureProperty ( capture, CV_CAP_PROP_FRAME_WIDTH );
  height	= (int) cvGetCaptureProperty ( capture, CV_CAP_PROP_FRAME_HEIGHT );

  cvNamedWindow( "live", 1 );
  cvNamedWindow( "gray", 1 );
  //cvNamedWindow( "edges", 1 );
  cvNamedWindow( "difference", 1 );
  cvNamedWindow( "template", 1 );

  gray = cvCreateImage ( cvSize ( width, height ), IPL_DEPTH_8U, 1 );
  if ( !gray ) {
    printf ( "failed to create gray image!!!\n" );
    exit(-1);
  }

  //edges = cvCreateImage ( cvSize ( width, height ), IPL_DEPTH_8U, 1 );
  //if ( !edges ) {
    //printf ( "Failed to create edges image!!!\n" );
    //exit(-1);
  //}

  templateImg = cvCreateImage ( cvSize ( width, height ), IPL_DEPTH_8U, 1 );
  if ( !templateImg ) {
    printf ( "Failed to create templateImg image!!!\n" );
    exit(-1);
  }

  difference = cvCreateImage ( cvSize ( width, height ), IPL_DEPTH_8U, 3 );
  if ( !difference ) {
    printf ( "failed to create difference image!!!\n" );
    exit(-1);
  }

  mhi = cvCreateImage ( cvSize ( width, height ), IPL_DEPTH_32F, 1 );
  if ( !mhi ) {
    printf ( "failed to create mhi image!!!\n" );
    exit(-1);
  }

  orient = cvCreateImage ( cvSize ( width, height ), IPL_DEPTH_32F, 1 );
  if ( !orient ) {
    printf ( "failed to create orient image!!!\n" );
    exit(-1);
  }

  //
  // Set Region of Interest to the whole image
  cvResetImageROI ( gray );
  gray->origin = 1;


  if( capture )
  {
    cout << "In capture ..." << endl;
    while(run)
    {

      double timestamp = (double)clock()/CLOCKS_PER_SEC; // get current time in seconds

      img = cvQueryFrame( capture );
      frame = img;

      if( frame.empty() )
        break;
      if( img->origin == IPL_ORIGIN_TL )
        frame.copyTo( frameCopy );
      else
        flip( frame, frameCopy, 0 );

      cvtColor (frame, grayMat, CV_BGR2GRAY );

      //cvtColor (frame, edgesMat, CV_BGR2GRAY );
      //GaussianBlur(edgesMat, edgesMat, Size(7,7), 1.5, 1.5);
      //Canny(edgesMat, edgesMat, 0, 30, 3);
      //

      //cv::Mat differenceMat(frame);


      *gray = grayMat;
      if(templateMat.empty() ){
        templateMat = grayMat.clone();
        *templateImg = templateMat;
      }

      //*edges = edgesMat;

      // Do pre-filtering; Get binarized image with blobs
      //Filter ( gray );



      int key = cv::waitKey( 10 );
      if (key >= 0){
        switch ( key ) {
          case ESC_KEY:
            run = false;
            break;
          case T_KEY:
            printf("capture new template image\n");
            templateMat = grayMat.clone();
            *templateImg = templateMat;
            break;
          default:
            printf("%d key hit\n", key);
            break;
        }
      }


      cv::absdiff( grayMat, templateMat, differenceMat); // get difference between frames

      *difference = differenceMat;

      update_mhi(differenceMat, img, 30);

      cvShowImage( "live", img );
      cvShowImage( "gray", gray );
      cvShowImage( "difference", difference );
      //cvShowImage( "edges", edges );
      cvShowImage( "template", templateImg);

    }
  }

  cvReleaseCapture( &capture );
  //cvReleaseImage ( &img );
  //cvReleaseImage ( &edges);
  //cvReleaseImage ( &templateImg);
  //cvReleaseImage ( &difference);
  //cvReleaseImage ( &gray );
  cvDestroyWindow( "live" );
  cvDestroyWindow( "difference" );
  cvDestroyWindow( "gray" );
  //cvDestroyWindow( "edges" );
  cvDestroyWindow( "template" );

  return 0;
}
