uniform sampler2D tex;

in vec2 out_texcoord;
in vec4 out_color;

void main (void)
{
    gl_FragColor = texture2D(tex, out_texcoord) * out_color;
}
