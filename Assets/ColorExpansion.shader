Shader "Unlit/ColorExpansion"
{
	Properties
	{
		[HideInInspector] _MainTex ("Texture", 2D) = "white" {}
		[HideInInspector] _RGB ("RGB Color", Color) = (0,0,0,1)
		_RGBf ("RGB Components", Vector) = (0,0,0)
		_YCMf ("YMC Components", Vector) = (0,0,0)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		ZTest Always 
		ZWrite On

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			half4 _RGB;
			half3 _RGBf;
			half3 _YCMf;
			int _Expand;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half4 col = half4(0,0,0,1);
				col.r = clamp(_RGBf.r + _YCMf.r - _RGBf.g/2 + _YCMf.b - _RGBf.b / 2, 0, 1);
				return col;
			}
			ENDCG
		}
	}
}
