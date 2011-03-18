uniform sampler2D tex;

in vec2 out_texcoord;
in vec4 out_color;

void main (void)
{
    vec4 color = texture2D(tex, out_texcoord);
    color.a = color.r;
    gl_FragColor = color * out_color;
}
