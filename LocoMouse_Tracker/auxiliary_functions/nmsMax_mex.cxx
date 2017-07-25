/* headercode */
#include <math.h>
/*endheadercode*/
#include <mex.h>

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
   if (!mxIsDouble(prhs[0]))
     mexErrMsgTxt("D2_coordiantes must be a matrix of doubles.");
   if (!mxIsDouble(prhs[1]))
     mexErrMsgTxt("box_size must be a matrix of doubles.");
   if (!mxIsDouble(prhs[2]))
     mexErrMsgTxt("scores must be a matrix of doubles.");
   if (!mxIsDouble(prhs[3]))
     mexErrMsgTxt("coordinates must be a matrix of doubles.");
   if (!mxIsDouble(prhs[4]))
     mexErrMsgTxt("overlap must be a matrix of doubles.");
   if (nlhs != 1)
     mexErrMsgTxt("nmsMax_mex must have exactly 1 output.");
   if (nrhs != 5)
     mexErrMsgTxt("nmsMax_mex must have exactly 5 inputs.");

   mxArray const* D2_coordinates_start_mx = prhs[0];
   mxArray const* D2_coordinates_end_mx = prhs[1];
   mxArray const* box_size_mx = prhs[2];
   mxArray const* scores_mx = prhs[3];
   mxArray const* overlap_mx = prhs[4];
  
   double const* D2_coordinates_s = mxGetPr(D2_coordinates_start_mx);
   double const* D2_coordinates_e = mxGetPr(D2_coordinates_end_mx);
   
   double const* box_size = mxGetPr(box_size_mx);
   double const* scores = mxGetPr(scores_mx);
   double const* overlap = mxGetPr(overlap_mx);
   
   //Input size:
   int D2_coordinates_sr = mxGetN(D2_coordinates_start_mx);
   int D2_coordinates_sc = mxGetM(D2_coordinates_start_mx);
   
   int scores_sr = mxGetM(scores_mx);
   int scores_sc = mxGetM(scores_mx);
   
   // make output array
   plhs[0] = mxCreateLogicalMatrix(1, D2_coordinates_sr);
 
   // This is initialized to false true:
   bool* keep = mxGetLogicals(plhs[0]);

   double area2 = box_size[0] * box_size[1] * 2;
    double l_zero, l_one, o, r, u, start_zero, start_one, end_zero, end_one;

   double const* D2_coordinates_inloop_s = D2_coordinates_s;
   double const* D2_coordinates_inloop_e = D2_coordinates_e;

   int counter = 0;

   for (int i = 0; i < D2_coordinates_sr - 1; ++i, D2_coordinates_s += 2, D2_coordinates_e += 2) {

     D2_coordinates_inloop_s = D2_coordinates_s + 2;
     D2_coordinates_inloop_e = D2_coordinates_e + 2;

    //mexPrintf("D2_inner: %f %f\n",D2_coordinates_inloop_s[0],D2_coordinates_inloop_s[1]);
     
     
      for (int j = i+1; j < D2_coordinates_sr; ++j, D2_coordinates_inloop_s += 2, D2_coordinates_inloop_e += 2) {

         if (keep[j])
            continue;
	 
         //Maximum of start pos 0:
         if (D2_coordinates_inloop_s[0] > D2_coordinates_s[0]) {
         start_zero = D2_coordinates_inloop_s[0];
         }
         else {
         start_zero = D2_coordinates_s[0];
         }

	 //Minimum of end pos 0:
         if (D2_coordinates_inloop_e[0] > D2_coordinates_e[0]) {
         end_zero = D2_coordinates_e[0];
         }
         else {
         end_zero = D2_coordinates_inloop_e[0];
         }

         l_zero = end_zero - start_zero;
         if (l_zero <= 0)
             continue;

         //Maximum of start pos 1:
         if (D2_coordinates_inloop_s[1] > D2_coordinates_s[1]) {
         start_one = D2_coordinates_inloop_s[1];
         }
         else {
         start_one = D2_coordinates_s[1];
         }

         //Minimum of end pos 1:
         if (D2_coordinates_inloop_e[1] > D2_coordinates_e[1]) {
         end_one = D2_coordinates_e[1];
         }
         else {
         end_one = D2_coordinates_inloop_e[1];
         }

         l_one = end_one - start_one;
         
         if (l_one <= 0)
             continue;

         //Compute the ratio
         o = (l_zero * l_one);
         u = area2 - o;
	 r = o/u;

	 
         if (r > overlap[0]) {
	    keep[j] = true;
	    }
        
      } 
     }
   }
