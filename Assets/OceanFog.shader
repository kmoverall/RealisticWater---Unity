Shader "PostProcess/OceanFog"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_StartFade ("Start Fade", Vector) = (0, 0, 0, 1)
		_EndFade ("End Fade", Vector) = (10, 50, 100, 1)
		_SurfaceHeight ("Surface Height", Float) = 5
		_Visibility ("Visibility", Float) = 50
		[HideInInspector] _CameraBGColor ("Camera Background Color", Color) = (49, 77, 121, 1)
	}
	SubShader
	{
		// No culling or depth
		ZTest Always Cull Off ZWrite Off Fog { Mode Off }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			sampler2D _CameraDepthTexture;
			half4 _StartFade;
			half4 _EndFade;
			half4 _CameraBGColor;
			half _SurfaceHeight;
			half _Visibility;
			float4x4 _ViewProjInv;
			uniform float4x4 _FrustumCornersWS;
			uniform float4 _CameraWS;

			uniform float4 _MainTex_TexelSize;


			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 uv_depth : TEXCOORD1;
				float4 interpolatedRay : TEXCOORD2;
			};

			v2f vert (appdata_img v)
			{
				v2f o;
				half index = v.vertex.z;
				v.vertex.z = 0.1;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.texcoord.xy;
				o.uv_depth = v.texcoord.xy;

				#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
					o.uv.y = 1-o.uv.y;
				#endif	

				o.interpolatedRay = _FrustumCornersWS[(int)index];
				o.interpolatedRay.w = index;				

				return o;
			}
			
			sampler2D _MainTex;

			fixed4 frag (v2f i) : SV_Target
			{
				// Reconstruct world space position & direction
				// towards this screen pixel.
				float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv_depth);
				float dpth = Linear01Depth(rawDepth);
				float4 wsDir = dpth * i.interpolatedRay;
				float4 wsPos = _CameraWS + wsDir;
			
				float pxlDist; 
				pxlDist = length(wsDir);
				pxlDist -= _ProjectionParams.y;

				half pxlDepth = _SurfaceHeight - wsPos.y;
				half camDepth = _SurfaceHeight - _CameraWS.y;
				
				half4 col = tex2D(_MainTex, i.uv);
				//Pixel and camera are out of water
				if (pxlDepth < 0 && camDepth < 0) {
					return col;
				}

				half dist = Linear01Depth(tex2D(_CameraDepthTexture, i.uv_depth));
				//Calculate the amount of water between pixel and camera if one is out of water
				if (camDepth < 0) {
					pxlDist *= 1 - (-1 * camDepth) / abs(wsPos.y - _CameraWS.y);
				}

				half maxDist = _ProjectionParams.z;
			
				half4 fade;
				half4 depthFade;
				half4 fogColor;
				half4 black = half4(0,0,0,1);

				depthFade = pxlDepth * (1 / (_EndFade - _StartFade)) - (_StartFade/(_EndFade - _StartFade));
				depthFade = clamp(depthFade, 0, 1);
				fogColor = lerp(_CameraBGColor, black, depthFade);
				half fogFade = (pxlDist / _Visibility);
				fogFade = clamp(fogFade, 0, 1);
	
				fade = (pxlDist + pxlDepth) * (1 / (_EndFade - _StartFade)) - (_StartFade/(_EndFade - _StartFade));
				fade = clamp(fade, 0, 1);
	
				col = lerp(col, black, fade);
				col = lerp(col, fogColor, fogFade);

				return col;
			}
			ENDCG
		}
	}
}
