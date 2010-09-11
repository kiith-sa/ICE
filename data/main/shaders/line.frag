uniform sampler2D tex;

void main (void)
{
    //For texturing, we'd do:
	//vec4 color = texture2D(tex,gl_TexCoord[0].st);
    //To set everything to red, we'd do:
    //vec4 color = vec4(1.0, 0.0, 0.0, 1.0);

    vec4 color = gl_Color;

	gl_FragColor = color;

}
