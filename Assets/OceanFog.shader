Shader "PostProcess/OceanFog"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_ColorFade ("Color Fade", Vector) = (0.624, 0.0325, 0.00635, 1)
		_SurfaceHeight ("Surface Height", Float) = 5
		_Density ("Particle Density", Float) = 0.00625
		_WaterColor ("Particle Color", Vector) = (1, 1, 1, 1)
		_SkyFog ("Air Fog Density", Float) = 0.0002
		[HideInInspector] _SunColor ("Sun Color", Vector) = (1, 1, 1, 1)
		[HideInInspector] _SunIntensity ("Sun Intensity", Float) = 1
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
			half4 _ColorFade;
			half4 _CameraBGColor;
			half _SkyFog;
			half _SurfaceHeight;
			half _Density;
			half4 _WaterColor;
			half4 _SunColor;
			half _SunIntensity;
			float4x4 _ViewProjInv;
			uniform float4x4 _FrustumCornersWS;
			uniform float4 _CameraWS;

			uniform float4 _MainTex_TexelSize;

			float4 applyFog(float dist, float4 density, float4 color, float4 src)
			{
				//This is the formula I = e^(-cx) * I_0, where c is the attenuation constant, x is the distance, and I is the intensity that penetrates the substance
				float4 f = dist * density * 1.4426950408f; // 1 / ln(2)
				f = exp2(-f);
				return lerp(color, src, f);
			}

			float4 applyWaterFog(float waterDist, float waterDepth, float camDepth, float4 viewDir, float4 src)
			{
				float4 depthFade;
				float4 fogColor;
				float4 upColor;
				float4 downColor;
				float4 lightColor;
				float4 white = float4(1, 1, 1, 1);
				float4 black = float4(0, 0, 0, 1);

				//Determine Fog Color
				float clampedCamDepth = max(camDepth, 0);
				lightColor = lerp(unity_AmbientSky, _SunColor, _SunIntensity) * _WaterColor;
				fogColor = applyFog(clampedCamDepth + lerp((1/_Density)*2, 0, (viewDir.y+1)/2), _ColorFade, black, lightColor);

				src = applyFog(waterDist + waterDepth, _ColorFade, black, src);
				src = applyFog(waterDist, _Density, fogColor, src);

				return src;
			}

			float4 applyAirFog(float airDist, float4 src) {
				return applyFog(airDist, _SkyFog, _CameraBGColor, src);
			}

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
				float waterDist = pxlDist;
				float airDist = pxlDist;

				float pxlDepth = _SurfaceHeight - wsPos.y;
				float waterDepth = pxlDepth;
				float camDepth = _SurfaceHeight - _CameraWS.y;
				
				half4 col = tex2D(_MainTex, i.uv);

				//Calculate the amount of water between pixel and camera if one of the two is out of water
				if (camDepth < 0 && pxlDepth < 0) {
					waterDist = 0;
					col = applyAirFog(pxlDist, col);
				}
				else if (camDepth >= 0 && pxlDepth >= 0) {
					airDist = 0;
					col = applyWaterFog(waterDist, waterDepth, camDepth, normalize(wsDir), col);
				}
				else if (camDepth < 0 && pxlDepth >= 0) {
					waterDist *= 1 - (-1 * camDepth) / abs(wsPos.y - _CameraWS.y);
					airDist = pxlDist - waterDist;
					col = applyWaterFog(waterDist, waterDepth, camDepth, normalize(wsDir), col);
					col = applyAirFog(airDist, col);
				}
				else {
					waterDist *= camDepth / abs(wsPos.y - _CameraWS.y);
					airDist = pxlDist - waterDist;
					//Clamping to 0 makes above water pixels color as if they were on the surface
					waterDepth = 0;
					col = applyAirFog(airDist, col);
					col = applyWaterFog(waterDist, waterDepth, camDepth, normalize(wsDir), col);
				}

				return col;
			}

			
			ENDCG
		}
	}
}
