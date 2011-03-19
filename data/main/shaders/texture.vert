in vec2 in_position;
in vec2 in_texcoord;
in vec4 in_color;

varying vec2 out_texcoord;
varying vec4 out_color;

uniform mat4 mvp_matrix;

void main (void)
{
    out_texcoord = in_texcoord;
    out_color = in_color;
    gl_Position = mvp_matrix * vec4(in_position, 0, 1);
}
