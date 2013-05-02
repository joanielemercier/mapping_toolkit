//@author: woei
//@help: creates 2d sprites on the GPU
//@tags: sprite, quad, billboard
// PARAMETERS-------------------------------------------------------------------
//transforms
float4x4 tWVP: WORLDVIEWPROJECTION;

//texture
texture Tex <string uiname="Texture";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};
float4x4 tTex: TEXTUREMATRIX <string uiname="Texture Transform";>;

texture pTex <string uiname="Position Texture";>;
sampler pSamp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (pTex);          //apply a texture to the sampler
    MipFilter = POINT; MinFilter = POINT; MagFilter = POINT;
	AddressU = clamp; AddressV = wrap;
};
int2 bbS <string uiname="Backbuffer Size";> = {400,300};

texture cTex <string uiname="Color Texture";>;
sampler cSamp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (cTex);          
    MipFilter = POINT; MinFilter = POINT; MagFilter = POINT;
	AddressU = clamp; AddressV = wrap;
};

struct vs2ps
{
    float4 PosWVP: POSITION;
    float4 TexCd : TEXCOORD0;
	float4 SColor : COLOR0;
};
// VERTEXSHADER-----------------------------------------------------------------
vs2ps VS_Spline(float4 PosO: POSITION, float3 NormO: NORMAL, float4 TexCd : TEXCOORD0, float4 PosCd : TEXCOORD1)
{
    vs2ps Out = (vs2ps)0;
	float4 s = tex2Dlod(pSamp, PosCd);
	
	PosO.xy*= s.zw;
	PosO.xy += s.xy;
    //PosO = mul(PosO, tW);
	
	
	Out.PosWVP = mul(PosO, tWVP);
	
    Out.TexCd = mul(TexCd, tTex);
	Out.SColor = tex2Dlod(cSamp, PosCd);
    return Out;
}
// PIXELSHADER------------------------------------------------------------------
float4 PS(vs2ps In): COLOR
{
	float4 col = tex2D(Samp, In.TexCd);
	col *= In.SColor;
	return col ;
} 
// TECHNIQUES-------------------------------------------------------------------
technique Sprite
{
    pass P0
    {
        VertexShader = compile vs_3_0 VS_Spline();
        PixelShader = compile ps_3_0 PS();
    }
}
