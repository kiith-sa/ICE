uniform sampler2D tex;

varying vec2 out_texcoord;
varying vec4 out_color;

void main (void)
{
    vec4 color = texture2D(tex, out_texcoord);
    color.a = color.g = color.b = color.r;
    gl_FragColor = color * out_color;
}
