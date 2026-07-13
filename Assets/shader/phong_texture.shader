Shader "lit/phong_texture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AOMap("AO Map",2D) = "white"{}
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
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal_dir : TEXCOORD1;
                float3 pos_world : TEXCOORD2;
                
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Shininess;
            float _SpecIntensity;
            sampler2D _AOMap;
			sampler2D _SpecMask;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal_dir = normalize(mul(float4(v.normal,0),unity_WorldToObject).xyz);
                o.pos_world = mul(unity_ObjectToWorld,v.vertex).xyz;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                //Texture
                half4 base_col = tex2D(_MainTex, i.uv);
                half4 ao_color = tex2D(_AOMap,i.uv);
                half4 spec_mask = tex2D(_SpecMask, i.uv);
                

                half3 view_dir = normalize(_WorldSpaceCameraPos.xyz - i.pos_world);
                half3 normal_dir = normalize(i.normal_dir);

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
