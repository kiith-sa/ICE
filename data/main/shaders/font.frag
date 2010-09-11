uniform sampler2D tex;

void main (void)
{
	vec4 color = texture2D(tex,gl_TexCoord[0].st);
    color.a = color.r;
    color = color * gl_Color;
	gl_FragColor = color;
}
