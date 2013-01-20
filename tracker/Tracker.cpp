#include "opencv2/objdetect/objdetect.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/imgproc/imgproc.hpp"


#include <iostream>
#include <stdlib.h>
#include <stdio.h>
#include <cstdio>
#include <cmath>


#define ESC_KEY 27
#define T_KEY 116
#define SAPCE_BAR 32


using namespace std;
using namespace cv;

// Forwards
//void Filter ( IplImage * img );
//void Find ( IplImage * src, IplImage * img );

//
// Global variables
int		width = 1;
int		height = 1;
CvFont	_idFont;

int main( int argc, const char** argv )
{
  CvCapture* capture = 0;
  Mat frame, frameCopy, image, grayMat, edgesMat;
  Mat templateMat;

  IplImage	*	img		= NULL;
  IplImage	*	gray	= NULL;
  IplImage	*	edges	= NULL;
  IplImage	*	templateImg = NULL;
  float			angle	= 0.0;

  bool run = true;

  // Initialize the Font used to draw into the source image
  cvInitFont ( &_idFont, CV_FONT_VECTOR0, 0.5, 0.5, 0.0, 1 );



  capture = cvCaptureFromCAM( 0 ); //0=default, -1=any camera, 1..99=your camera
  if(!capture) cout << "No camera detected" << endl;

  width	= (int) cvGetCaptureProperty ( capture, CV_CAP_PROP_FRAME_WIDTH );
  height	= (int) cvGetCaptureProperty ( capture, CV_CAP_PROP_FRAME_HEIGHT );

  cvNamedWindow( "result", 1 );
  cvNamedWindow( "gray", 1 );
  cvNamedWindow( "edges", 1 );
  cvNamedWindow( "template", 1 );

  gray = cvCreateImage ( cvSize ( width, height ), IPL_DEPTH_8U, 1 );
  if ( !gray ) {
    printf ( "Failed to create gray image!!!\n" );
    exit(-1);
  }

  edges = cvCreateImage ( cvSize ( width, height ), IPL_DEPTH_8U, 1 );
  if ( !edges ) {
    printf ( "Failed to create edges image!!!\n" );
    exit(-1);
  }

  templateImg = cvCreateImage ( cvSize ( width, height ), IPL_DEPTH_8U, 1 );
  if ( !templateImg ) {
    printf ( "Failed to create templateImg image!!!\n" );
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
      img = cvQueryFrame( capture );
      frame = img;

      if( frame.empty() )
        break;
      if( img->origin == IPL_ORIGIN_TL )
        frame.copyTo( frameCopy );
      else
        flip( frame, frameCopy, 0 );

      cvtColor (frame, grayMat, CV_BGR2GRAY );

      cvtColor (frame, edgesMat, CV_BGR2GRAY );
      GaussianBlur(edgesMat, edgesMat, Size(7,7), 1.5, 1.5);
      Canny(edgesMat, edgesMat, 0, 30, 3);


      *gray = grayMat;
      if(templateMat.empty() ){
        templateMat = grayMat.clone();
        *templateImg = templateMat;
      }

      *edges = edgesMat;

      // Do pre-filtering; Get binarized image with blobs
      //Filter ( gray );



      int key = waitKey( 10 );
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

      cvShowImage( "result", img );
      cvShowImage( "gray", gray );
      cvShowImage( "edges", edges );
      cvShowImage( "template", templateImg);

    }
  }

  cvReleaseCapture( &capture );
  cvReleaseImage ( &img );
  cvReleaseImage ( &edges);
  cvReleaseImage ( &templateImg);
  cvReleaseImage ( &gray );
  cvDestroyWindow( "result" );
  cvDestroyWindow( "gray" );
  cvDestroyWindow( "edges" );
  cvDestroyWindow( "template" );

  return 0;
}
