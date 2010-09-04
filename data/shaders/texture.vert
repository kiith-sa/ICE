void main (void)
{
	//If we would want to use the texture matrix:
	//gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;

	gl_TexCoord[0] = gl_MultiTexCoord0;       
	gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    gl_FrontColor = gl_Color;
}
