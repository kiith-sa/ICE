uniform sampler2D tex;

void main (void)
{
	//vec4 color = texture2D(tex,gl_TexCoord[0].st);
	vec4 color = texture2D(tex,gl_TexCoord[0].st) * gl_Color;

    //To set everything to red, we'd do:
    //vec4 color = vec4(1.0, 0.0, 0.0, 1.0);

	gl_FragColor = color;
}
