Shader "Custom/ColorExpansionLit" {
	Properties {
		_Color("RGB Color", Color) = (0,0,0)
		_RGB("RGB Components", Vector) = (0,0,0)
		_YCM("YMC Components", Vector) = (0,0,0)
		_Expand("Expand RGB", Int) = 0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		struct Input {
			float2 uv_MainTex;
		};

		float3 _Color;
		float3 _RGB;
		float3 _YCM;
		int _Expand;

		float3 RGBtoHSV(float3 col)
		{
			float3 hsv;
			float mn, mx, delta;
			mn = min(col.r, min(col.g, col.b));
			mx = max(col.r, max(col.g, col.b));
			hsv.b = mx;				// v
			delta = mx - mn;
			if (mx != 0)
				hsv.g = delta / mx;		// s
			else {
				// r = g = b = 0		// s = 0, v is undefined
				hsv.g = 0;
				hsv.r = 0;
				return hsv;
			}
			if (col.r == mx)
				hsv.r = (col.g - col.b) / delta;		// between yellow & magenta
			else if (col.g == mx)
				hsv.r = 2 + (col.b - col.r) / delta;	// between cyan & yellow
			else
				hsv.r = 4 + (col.r - col.g) / delta;	// between magenta & cyan
			hsv.r *= 60;				// degrees
			if (hsv.r < 0)
				hsv.r += 360;

			return hsv;
		}

		float3 HSVtoRGB(float3 hsv)
		{
			int i;
			float f, p, q, t;
			float3 col;
			if (hsv.g == 0) {
				// achromatic (grey)
				col.r = col.g = col.b = hsv.b;
				return col;
			}
			hsv.r /= 60;			// sector 0 to 5
			i = floor(hsv.r);
			f = hsv.r - i;			// factorial part of h
			p = hsv.b * (1 - hsv.g);
			q = hsv.b * (1 - hsv.g * f);
			t = hsv.b * (1 - hsv.g * (1 - f));
			switch (i) {
			case 0:
				col.r = hsv.b;
				col.g = t;
				col.b = p;
				break;
			case 1:
				col.r = q;
				col.g = hsv.b;
				col.b = p;
				break;
			case 2:
				col.r = p;
				col.g = hsv.b;
				col.b = t;
				break;
			case 3:
				col.r = p;
				col.g = q;
				col.b = hsv.b;
				break;
			case 4:
				col.r = t;
				col.g = p;
				col.b = hsv.b;
				break;
			default:		// case 5:
				col.r = hsv.b;
				col.g = p;
				col.b = q;
				break;
			}

			return col;
		}

		float3 RYGCBMtoHSV(float3 col, float3 ycm)
		{
			float3 hsv;
			float mn, mx, delta;
			mn = min(col.r, min(col.g, min(col.b, min(ycm.r, min(ycm.g, ycm.b)))));
			mx = max(col.r, max(col.g, max(col.b, max(ycm.r, max(ycm.g, ycm.b)))));
			hsv.b = mx;				// v
			delta = mx - mn;
			if (mx != 0)
				hsv.g = delta / mx;		// s
			else {
				// r = g = b = 0		// s = 0, v is undefined
				hsv.g = 0;
				hsv.r = 0;
				return hsv;
			}
			if (col.r == mx)
				hsv.r = (ycm.r - ycm.b) / delta;
			else if (ycm.r == mx)
				hsv.r = 2 + (col.g - col.r) / delta;
			else if (col.g == mx)
				hsv.r = 4 + (ycm.g - ycm.r) / delta;
			else if (ycm.g == mx)
				hsv.r = 6 + (col.b - col.g) / delta;
			else if (col.b == mx)
				hsv.r = 8 + (ycm.b - ycm.g) / delta;
			else
				hsv.r = 10 + (col.r - col.b) / delta;
			hsv.r *= 30;				// degrees
			if (hsv.r < 0)
				hsv.r += 360;

			return hsv;
		}

		float3 HSVtoRYGCBM(float3 hsv, int channels)
		{
			int i;
			float f, p, q, t;
			float3 col[2];
			float test;
			if (hsv.g == 0) {
				// achromatic (grey)
				col[0].r = col[0].g = col[0].b = col[1].r = col[1].g = col[1].b = hsv.b;
				return col[channels];
			}
			hsv.r /= 30;			// sector 0 to 11
			i = floor(hsv.r);
			f = hsv.r - i;			// factorial part of h
			p = hsv.b * (1 - hsv.g);
			q = hsv.b * (1 - hsv.g * f);
			t = hsv.b * (1 - hsv.g * (1 - f));

			switch (i) {
			case 0:
				col[0].r = hsv.b;
				col[1].r = t;
				col[0].g = p;
				col[1].g = p;
				col[0].b = p;
				col[1].b = p;
				return col[channels];
				break;
			case 1:
				col[0].r = q;
				col[1].r = hsv.b;
				col[0].g = p;
				col[1].g = p;
				col[0].b = p;
				col[1].b = p;
				return col[channels];
				break;
			case 2:
				col[0].r = p;
				col[1].r = hsv.b;
				col[0].g = t;
				col[1].g = p;
				col[0].b = p;
				col[1].b = p;
				return col[channels];
				break;
			case 3:
				col[0].r = p;
				col[1].r = q;
				col[0].g = hsv.b;
				col[1].g = p;
				col[0].b = p;
				col[1].b = p;
				return col[channels];
				break;
			case 4:
				col[0].r = p;
				col[1].r = p;
				col[0].g = hsv.b;
				col[1].g = t;
				col[0].b = p;
				col[1].b = p;
				return col[channels];
				break;
			case 5:
				col[0].r = p;
				col[1].r = p;
				col[0].g = q;
				col[1].g = hsv.b;
				col[0].b = p;
				col[1].b = p;
				return col[channels];
				break;
			case 6:
				col[0].r = p;
				col[1].r = p;
				col[0].g = p;
				col[1].g = hsv.b;
				col[0].b = t;
				col[1].b = p;
				return col[channels];
				break;
			case 7:
				col[0].r = p;
				col[1].r = p;
				col[0].g = p;
				col[1].g = q;
				col[0].b = hsv.b;
				col[1].b = p;
				return col[channels];
				break;
			case 8:
				col[0].r = p;
				col[1].r = p;
				col[0].g = p;
				col[1].g = p;
				col[0].b = hsv.b;
				col[1].b = t;
				return col[channels];
				break;
			case 9:
				col[0].r = p;
				col[1].r = p;
				col[0].g = p;
				col[1].g = p;
				col[0].b = q;
				col[1].b = hsv.b;
				return col[channels];
				break;
			case 10:
				col[0].r = t;
				col[1].r = p;
				col[0].g = p;
				col[1].g = p;
				col[0].b = p;
				col[1].b = hsv.b;
				return col[channels];
				break;
			default:		// case 11:
				col[0].r = hsv.b;
				col[1].r = p;
				col[0].g = p;
				col[1].g = p;
				col[0].b = p;
				col[1].b = q;
				return col[channels];
				break;
			}
		}

		void surf (Input IN, inout SurfaceOutputStandard o) {
			float3 hsv = RGBtoHSV(_Color);
			float3 rgb = HSVtoRYGCBM(hsv, 0);
			float3 ycm = HSVtoRYGCBM(hsv, 1);
			hsv = RYGCBMtoHSV(rgb, ycm);
			float3 col = HSVtoRGB(hsv);
			o.Albedo = col;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
