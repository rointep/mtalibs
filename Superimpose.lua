
Superimpose = {}
Superimpose.data = {
	renderWidth = renderWidth,
	renderHeight = renderHeight,

	worldDimension = worldDimension or 0,

	entities = {},

	-- private fields
	_RT = renderTarget,
	_shader1 = shader1,
	_shader2 = shader2,
}

function Superimpose.Load(renderWidth, renderHeight, worldDimension)
	if fileExists("render.dat") then fileDelete("render.dat") end
	local file = fileCreate("render.dat"); fileWrite(file, Superimpose.SHADERFILE1); fileClose(file);
	if fileExists("superimpose.dat") then fileDelete("superimpose.dat") end
	local file = fileCreate("superimpose.dat"); fileWrite(file, Superimpose.SHADERFILE2); fileClose(file);


	local renderTarget = dxCreateRenderTarget(renderWidth, renderHeight, true)

	local shader1 = dxCreateShader("render.dat", -100, 0, false, "all")
	local shader2 = dxCreateShader("superimpose.dat")
	dxSetShaderValue(shader2, "Tex0", renderTarget)
	dxSetShaderValue(shader2, "size", { renderWidth, renderHeight })

	fileDelete("render.dat")
	fileDelete("superimpose.dat")

	Superimpose.data.renderWidth = renderWidth and renderWidth or Superimpose.data.renderWidth
	Superimpose.data.renderHeight = renderHeight and renderHeight or Superimpose.data.renderHeight
	
	Superimpose.data.worldDimension = worldDimension and worldDimension or Superimpose.data.worldDimension

	-- private fields
	Superimpose.data._RT = renderTarget
	Superimpose.data._shader1 = shader1
	Superimpose.data._shader2 = shader2

	return true
end


function Superimpose.Unload()
	if isElement(Superimpose.data._RT) then destroyElement(Superimpose.data._RT) end
	if isElement(Superimpose.data._shader1) then destroyElement(Superimpose.data._shader1) end
	if isElement(Superimpose.data._shader2) then destroyElement(Superimpose.data._shader2) end

	return true
end



function Superimpose.SetResolution(renderWidth, renderHeight)
	Superimpose.data.renderWidth = renderWidth
	Superimpose.data.renderHeight = renderHeight
	return true
end


function Superimpose.SetDimension(dimension)
	Superimpose.data.worldDimension = dimension
	return true
end


function Superimpose.AddEntity(entity, diffuseMultiplier)
	for i,k in ipairs(Superimpose.data.entities) do
		if k == entity then
			return false
		end
	end

	setElementDimension(entity, Superimpose.data.worldDimension)
	engineApplyShaderToWorldTexture(Superimpose.data._shader1, "*", entity, false)
	dxSetShaderValue(Superimpose.data._shader1, "diffuseMultiplier", diffuseMultiplier or 1.0)

	table.insert(Superimpose.data.entities, entity)
	return true
end

function Superimpose.SetColorMultiplier(colorMultiplier)
	dxSetShaderValue(Superimpose.data._shader1, "colorMultiplier", unpack(colorMultiplier))
end

function Superimpose.RemoveEntity(entity)
	for i,k in ipairs(Superimpose.data.entities) do
		if k == entity then
			engineRemoveShaderFromWorldTexture(Superimpose.data._shader1, "*", entity)
			table.remove(Superimpose.data.entities, i)
			return true
		end
	end
	return false
end

function Superimpose.RemoveAllEntities()
	for i,k in ipairs(Superimpose.data.entities) do
		engineRemoveShaderFromWorldTexture(Superimpose.data._shader1, "*", entity)
	end
	Superimpose.data.entities = {}
	Superimpose.SetColorMultiplier({1.0, 1.0, 1.0, 1.0})
end





--******************************************************************************************************
--
-- FrameStart and FrameEnd
--
-- Call FrameStart before drawing any DirectX stuff to ensure the superimposed entities get drawn on top
-- Call FrameEnd after you're done with your drawing
--
--
--******************************************************************************************************
function Superimpose.FrameStart()
	--outputDebugString("[" .. getTickCount() .. "] FrameStart")
	--dxSetBlendMode("modulate_add")
	dxSetRenderTarget(Superimpose.data._RT, true)
end


function Superimpose.FrameEnd()
	--outputDebugString("[" .. getTickCount() .. "] FrameEnd")
	dxSetRenderTarget()
	dxSetBlendMode("add")
	dxDrawImage(0, 0, Superimpose.data.renderWidth, Superimpose.data.renderHeight, Superimpose.data._shader2)
	dxSetBlendMode("blend")
end






Superimpose.SHADERFILE1 = [[
	//
	// Matrices
	//
	float4x4 gWorld : WORLD;
	float4x4 gView : VIEW;
	float4x4 gProjection : PROJECTION;
	float4x4 gWorldView : WORLDVIEW;
	float4x4 gWorldViewProjection : WORLDVIEWPROJECTION;
	float4x4 gViewProjection : VIEWPROJECTION;
	float4x4 gViewInverse : VIEWINVERSE;
	float4x4 gWorldInverseTranspose : WORLDINVERSETRANSPOSE;
	float4x4 gViewInverseTranspose : VIEWINVERSETRANSPOSE;

	//
	// Camera
	//
	float3 gCameraPosition : CAMERAPOSITION;
	float3 gCameraDirection : CAMERADIRECTION;

	//
	// Seconds counter
	//
	float gTime : TIME;

	//
	// Strongest light influence
	//
	float4 gLightAmbient : LIGHTAMBIENT;
	float4 gLightDiffuse : LIGHTDIFFUSE;
	float4 gLightSpecular : LIGHTSPECULAR;
	float3 gLightDirection : LIGHTDIRECTION;

	//------------------------------------------------------------------------------------------
	// renderState (partial) - String value should be one of D3DRENDERSTATETYPE without the D3DRS_  http://msdn.microsoft.com/en-us/library/bb172599%28v=vs.85%29.aspx
	//------------------------------------------------------------------------------------------

	int gLighting                      < string renderState="LIGHTING"; >;                        //  = 137,

	float4 gGlobalAmbient              < string renderState="AMBIENT"; >;                    //  = 139,

	int gDiffuseMaterialSource         < string renderState="DIFFUSEMATERIALSOURCE"; >;           //  = 145,
	int gSpecularMaterialSource        < string renderState="SPECULARMATERIALSOURCE"; >;          //  = 146,
	int gAmbientMaterialSource         < string renderState="AMBIENTMATERIALSOURCE"; >;           //  = 147,
	int gEmissiveMaterialSource        < string renderState="EMISSIVEMATERIALSOURCE"; >;          //  = 148,


	//------------------------------------------------------------------------------------------
	// materialState - String value should be one of the members from D3DMATERIAL9  http://msdn.microsoft.com/en-us/library/bb172571%28v=VS.85%29.aspx
	//------------------------------------------------------------------------------------------

	float4 gMaterialAmbient     < string materialState="Ambient"; >;
	float4 gMaterialDiffuse     < string materialState="Diffuse"; >;
	float4 gMaterialSpecular    < string materialState="Specular"; >;
	float4 gMaterialEmissive    < string materialState="Emissive"; >;
	float gMaterialSpecPower    < string materialState="Power"; >;


	//------------------------------------------------------------------------------------------
	// textureState (partial) - String value should be a texture number followed by 'Texture'
	//------------------------------------------------------------------------------------------

	texture gTexture0           < string textureState="0,Texture"; >;
	texture gTexture1           < string textureState="1,Texture"; >;
	texture gTexture2           < string textureState="2,Texture"; >;
	texture gTexture3           < string textureState="3,Texture"; >;

	//------------------------------------------------------------------------------------------
	// MTACalcWorldNormal
	// - Rotate normal by current world matix
	//------------------------------------------------------------------------------------------
	float3 MTACalcWorldNormal( float3 InNormal )
	{
	    return mul(InNormal, (float3x3)gWorld);
	}


	//------------------------------------------------------------------------------------------
	// MTACalcGTAVehicleDiffuse
	// - Calculate GTA lighting for vehicles
	//------------------------------------------------------------------------------------------
	float4 MTACalcGTAVehicleDiffuse( float3 WorldNormal, float4 InDiffuse )
	{
	    // Calculate diffuse color by doing what D3D usually does
	    float4 ambient  = gAmbientMaterialSource  == 0 ? gMaterialAmbient  : InDiffuse;
	    float4 diffuse  = gDiffuseMaterialSource  == 0 ? gMaterialDiffuse  : InDiffuse;
	    float4 emissive = gEmissiveMaterialSource == 0 ? gMaterialEmissive : InDiffuse;

	    float4 TotalAmbient = ambient * ( gGlobalAmbient + gLightAmbient );

	    // Add the strongest light
	    float DirectionFactor = max(0,dot(WorldNormal, -gLightDirection ));
	    float4 TotalDiffuse = ( diffuse * gLightDiffuse * DirectionFactor );

	    float4 OutDiffuse = saturate(TotalDiffuse + TotalAmbient + emissive);
	    OutDiffuse.a *= diffuse.a;

	    return OutDiffuse;
	}


	//-----------------------------------------------------------------------
	//-- Variables
	//-----------------------------------------------------------------------
	float diffuseMultiplier = 1.0f;
	float4 colorMultiplier = float4(1.0f, 1.0f, 1.0f, 1.0f);



	//-----------------------------------------------------------------------
	//-- Sampler for the new texture
	//-----------------------------------------------------------------------
	sampler Sampler0 = sampler_state
	{
	    Texture = (gTexture0);
	};
	 
	 
	//-----------------------------------------------------------------------
	//-- Structure of data sent to the vertex shader
	//-----------------------------------------------------------------------
	struct VSInput
	{
	    float3 Position : POSITION0;
	    float3 Normal : NORMAL0;
	    float4 Diffuse : COLOR0;
	    float2 TexCoord : TEXCOORD0;
	};
	 
	//-----------------------------------------------------------------------
	//-- Structure of data sent to the pixel shader ( from the vertex shader )
	//-----------------------------------------------------------------------
	struct PSInput
	{
	    float4 Position : POSITION0;
	    float4 Diffuse : COLOR0;
	    float2 TexCoord : TEXCOORD0;
	};
	 
	 
	//--------------------------------------------------------------------------------------------
	//-- VertexShaderFunction
	//--  1. Read from VS structure
	//--  2. Process
	//--  3. Write to PS structure
	//--------------------------------------------------------------------------------------------
	PSInput VertexShaderFunction(VSInput VS)
	{
	    PSInput PS = (PSInput)0;
	 
	    //-- Calculate screen pos of vertex
	    PS.Position = mul(float4(VS.Position, 1.0), gWorldViewProjection);

	    //-- Pass through tex coord
	    PS.TexCoord = VS.TexCoord;
	 
	    // Calculate GTA lighting for vehicles
	    float3 WorldNormal = MTACalcWorldNormal( VS.Normal );
	    PS.Diffuse = MTACalcGTAVehicleDiffuse( WorldNormal, VS.Diffuse );
		PS.Diffuse *= diffuseMultiplier;
		PS.Position.z *= 0.01;

	    return PS;
	}
	 
	 
	//--------------------------------------------------------------------------------------------
	//-- PixelShaderFunction
	//--  1. Read from PS structure
	//--  2. Process
	//--  3. Return pixel color
	//--------------------------------------------------------------------------------------------
	float4 PixelShaderFunction(PSInput PS) : COLOR0
	{
	    //-- Get texture pixel
	    float4 texel = tex2D(Sampler0, PS.TexCoord);
	 
	    //-- Apply diffuse lighting
	    float4 finalColor = saturate(texel * PS.Diffuse);
	    finalColor *= colorMultiplier;
		//finalColor.a = 1.0;
	 
	    return finalColor;
	}
	 
	 
	//--------------------------------------------------------------------------------------------
	//-- Techniques
	//--------------------------------------------------------------------------------------------
	technique tec
	{
	    pass P1
	    {
	    	AlphaBlendEnable = TRUE;
			AlphaTestEnable = TRUE;
	        VertexShader = compile vs_2_0 VertexShaderFunction();
	        PixelShader = compile ps_2_0 PixelShaderFunction();
	    }
	}
]]



Superimpose.SHADERFILE2 = [[
	texture Tex0;
	float2 size;

	sampler Sampler0 = sampler_state
	{
	    Texture = (Tex0);
	};
	 
	struct VSInput
	{
	    float3 Position : POSITION0;
	    float4 Diffuse : COLOR0;
	    float2 TexCoord : TEXCOORD0;
	};
	 
	struct PSInput
	{
	    float4 Position : POSITION0;
	    float4 Diffuse : COLOR0;
	    float2 TexCoord : TEXCOORD0;
	};

	PSInput VertexShaderFunction(VSInput VS)
	{
	    PSInput PS = (PSInput)0;
	 
		float2 screenPos = float2(VS.Position.x / (size.x * 0.5), VS.Position.y / (size.y * 0.5));
	    PS.Position = float4(screenPos.x - 1.0 - (1.0 / size.x), -screenPos.y + 1.0 + (1.0 / size.y), 0.2, 1.0);
	    PS.TexCoord = VS.TexCoord;
	    PS.Diffuse = VS.Diffuse;
	 
	    return PS;
	}
	 
	float4 PixelShaderFunction(PSInput PS) : COLOR0
	{
	    //-- Get texture pixel
	    float4 texel = tex2D(Sampler0, PS.TexCoord);
	    float4 finalColor = texel;
	 
	    return finalColor;
	}

	technique tec
	{
	    pass P0
	    {
			ZEnable = TRUE;
			ZWriteEnable = TRUE;
			ZFunc = LESS;
			AlphaBlendEnable = TRUE;
			AlphaTestEnable = TRUE;
			//BlendOp = ADD;
			SrcBlend = DESTALPHA;
			DestBlend = INVDESTALPHA;
	        VertexShader = compile vs_2_0 VertexShaderFunction();
	        PixelShader = compile ps_2_0 PixelShaderFunction();
			//Texture[0] = Tex0;
	    }
	}
]]