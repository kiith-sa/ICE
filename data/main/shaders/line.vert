in vec2 in_position;
in vec4 in_color;

varying vec4 out_color;

void main (void)
{
    out_color = in_color;
    gl_Position = gl_ModelViewProjectionMatrix * vec4(in_position, 0, 1);
}
