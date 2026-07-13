Shader "lit/phong_normal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AOMap("AO Map",2D) = "white"{}
        _NormalMap("NormalMap",2D) = "bump"{}
		_NormalIntensity("Normal Intensity",Range(0.0,5.0)) = 1.0
        _SpecMask("Spec Mask",2D) = "white"{}
        _Shininess("Shininess",Range(0.01,100)) = 1.0
        _SpecIntensity("SpecIntensity",Range(0.01,5)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 pos_world : TEXCOORD1;
                float3 normal_dir : TEXCOORD2;
                float3 tangent_dir : TEXCOORD3;
				float3 binormal_dir : TEXCOORD4;
                
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _AOMap;

			sampler2D _SpecMask;
            float _SpecIntensity;

            sampler2D _NormalMap;
			float _NormalIntensity;

            float _Shininess;
            
        

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal_dir = normalize(mul(float4(v.normal,0),unity_WorldToObject).xyz);
                o.tangent_dir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
				o.binormal_dir = normalize(cross(o.normal_dir,o.tangent_dir)) * v.tangent.w;
                o.pos_world = mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                //Texture
                half4 base_col = tex2D(_MainTex, i.uv);
                half4 ao_color = tex2D(_AOMap,i.uv);
                half4 spec_mask = tex2D(_SpecMask, i.uv);
                half4 normalmap = tex2D(_NormalMap,i.uv);
                
                //Direction
                half3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
                half3 normal_dir = normalize(i.normal_dir);
                half3 tangent_dir = normalize(i.tangent_dir);
				half3 binormal_dir = normalize(i.binormal_dir);
                
                //NORMAL
                float3x3 TBN = float3x3(tangent_dir, binormal_dir,normal_dir);
                half3 normal_data = UnpackNormal(normalmap);
                normal_data.xy = normal_data.xy * _NormalIntensity;
                normal_dir = normalize(mul(normal_data.xyz,TBN));
                    //normal_dir = normalize(tangent_dir * normal_data.x * _NormalIntensity + binormal_dir * normal_data.y * _NormalIntensity + normal_dir * normal_data.z);

                //diffuse
                half3 light_dir = normalize(_WorldSpaceLightPos0.xyz);
                half3 diffuse_color = max(0,dot(normal_dir,light_dir)) * base_col.rgb;

                //specular
                half3 half_dir = normalize(light_dir + view_dir);
                half3 spec_color = pow(max(0,dot(normal_dir,half_dir)),_Shininess)* spec_mask.rgb;

                //ambient
                half3 ambient = (0,0,0);

                
                half3 final_color = (diffuse_color + spec_color * _SpecIntensity + ambient)
                        * ao_color.rgb;

                
                return half4(final_color,1.0);
            }
            ENDCG
        }
    }
}
