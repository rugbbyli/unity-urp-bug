Shader "Debug/UrpInstancingBug"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _ST ("ST", Vector) = (1, 1, 0, 0)
        _Flag ("Flag", Float) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 200

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // key point: enable instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 uvf: TEXCOORD0;
                float4 color : TEXCOORD1;
                
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            // key point: declare instance properties with a total length exceeding "8". For example, if you comment out the following _Flag property, the issue will not occur.
            UNITY_INSTANCING_BUFFER_START(SimpleLitUrp3_Props)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(float4, _ST)
                UNITY_DEFINE_INSTANCED_PROP(float, _Flag)
            UNITY_INSTANCING_BUFFER_END(SimpleLitUrp3_Props)

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
                
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                float flag = UNITY_ACCESS_INSTANCED_PROP(SimpleLitUrp3_Props, _Flag);
                float4 st = UNITY_ACCESS_INSTANCED_PROP(SimpleLitUrp3_Props, _ST);
                OUT.color = UNITY_ACCESS_INSTANCED_PROP(SimpleLitUrp3_Props, _Color);
                float2 uv = IN.uv * st.xy + st.zw;
                OUT.uvf = float3(uv, flag);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                
                half4 c = IN.color * half4(IN.uvf, 1);

                // key point: access the instancing property at least once in the frag function. For example, if you move the following line of code to be calculated in the vert function, the issue will not occur:
                const int lightCount = UNITY_ACCESS_INSTANCED_PROP(SimpleLitUrp3_Props, _Flag);
                
                // key point: The following loop has no practical purpose; it simply demonstrates accessing the contents of unity_LightIndices dynamically. It does not execute itself (since lightCount is 0), but if you change it to unity_LightIndices[0][0] or access other variables, the issue will not occur.
                for (int i = 0; i < lightCount; i++)
                {
                    c.a = unity_LightIndices[i / 4][i % 4];
                }
                
                return c;
            }
            ENDHLSL
        }
    }
    FallBack "Diffuse"
}