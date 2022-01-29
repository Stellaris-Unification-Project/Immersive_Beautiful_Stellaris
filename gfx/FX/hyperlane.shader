Includes = {
	"constants.fxh"
	"terra_incognita.fxh"
}

PixelShader =
{
	Samplers =
	{
		TerraIncognitaTexture =
		{
			Index = 0;
			MagFilter = "Linear";
			MinFilter = "Linear";
			AddressU = "Clamp"
			AddressV = "Clamp"
		}
	}
}

BlendState BlendState
{
	BlendEnable = yes
	AlphaTest = no
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
	WriteMask = "RED|GREEN|BLUE"
}

DepthStencilState DepthStencilState
{
	DepthEnable = no
}

VertexStruct VS_INPUT
{
	float3 vPosition  		: POSITION;
	float4 vPrimaryColor		: TEXCOORD0;
	float4 vSecondaryColor 	: TEXCOORD1;
};

VertexStruct VS_OUTPUT
{
	float4  vPosition 		: PDX_POSITION;
	float2  vPos 			: TEXCOORD0;
	float3  vPrimaryColor	: TEXCOORD1;
	float3  vSecondaryColor	: TEXCOORD2;
	float	vHasAccess		: TEXCOORD3;
	float   vSystemIsVisible	: TEXCOORD4;
};

ConstantBuffer( HyperLaneConstants, 0, 0 )
{
	float4x4 	ViewProjectionMatrix;
	float		vGlobalAlpha;
};

VertexShader =
{
	MainCode VertexShader
		ConstantBuffers = { HyperLaneConstants }
	[[
		VS_OUTPUT main(const VS_INPUT v )
		{
			VS_OUTPUT Out;
			Out.vPos = v.vPosition.xz;
			Out.vPosition  	= mul( ViewProjectionMatrix, float4( v.vPosition, 1.0 ) );
			Out.vPrimaryColor = float3(0.9, 0.95, 1.0);		//v.vPrimaryColor.rgb;
			Out.vSecondaryColor = float3(1.0, 0.4, 0.0);	//v.vSecondaryColor.rgb;
			Out.vHasAccess = v.vPrimaryColor.a;
			Out.vSystemIsVisible = v.vSecondaryColor.a;
			return Out;
		}

	]]
}

PixelShader =
{
	MainCode PixelShader
		ConstantBuffers = { HyperLaneConstants }
	[[
		static const float INCOGNITA_HYPERLANE_ALPHA = 0.03f;	//0.05f
		static const float DEFAULT_HYPERLANE_ALPHA = 0.1f;		//0.25f
		static const float NOACCESS_HYPERLANE_ALPHA = 0.11f;	//0.4f

		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
			float4 vPrimColor = float4( v.vPrimaryColor, 1.0f );
			float4 vSecColor = float4( v.vSecondaryColor, 1.0f );
			float4 vColor = lerp( vSecColor, vPrimColor, saturate( pow( abs(v.vHasAccess), 15 ) ) );

			// We want same color on Incognita lines regardless of vHasAccess, so use IgnoreSaturation version.
			vColor = ApplyTerraIncognitaIgnoreSaturation( vColor, v.vPos, 5.f, TerraIncognitaTexture );

			float fRegularAlpha = lerp( NOACCESS_HYPERLANE_ALPHA, DEFAULT_HYPERLANE_ALPHA, v.vHasAccess ) * vGlobalAlpha;
			float fIncognitaAlpha = INCOGNITA_HYPERLANE_ALPHA * saturate( pow( v.vSystemIsVisible, 4 ) ) * vGlobalAlpha;
			vColor.a = lerp( fIncognitaAlpha, fRegularAlpha, CalcTerraIncognitaValue( v.vPos, TerraIncognitaTexture ) );

			return vColor;
		}

	]]
}

Effect Hyperlane
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShader"
}
