#include "opencv2/objdetect/objdetect.hpp"
#include "opencv2/video/tracking.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/imgproc/imgproc.hpp"


#include <time.h>
//#include <ctype.h>
#include <iostream>
#include <stdlib.h>
#include <stdio.h>
#include <cstdio>
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

  difference = cvCreateImage ( cvSize ( width, height ), IPL_DEPTH_8U, 1 );
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

      double diff_threshold = 30.0;

      threshold( differenceMat, differenceMat, diff_threshold, 1, CV_THRESH_BINARY ); // and threshold it
      *difference = differenceMat;

      cvZero( mhi ); // clear MHI at the beginning

      cvUpdateMotionHistory( difference, mhi, timestamp, MHI_DURATION); // update differenceMat

      cvZero( difference );
      cvZero( orient );
      // convert MHI to blue 8u image
      cvCvtScale( mhi, difference, 255./MHI_DURATION,
                  (MHI_DURATION - timestamp)*255./MHI_DURATION );



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
