module videodriverutil;


import std.math;

import videodriver;
import vector2;
import line2;
import color;

void draw_circle(Vector2f center, float radius, 
                 Color color = Color(255, 255, 255, 255), uint vertex_count = 32)
in
{
    assert(radius >= 0, "Can't draw a circle with negative radius");
    assert(vertex_count >= 3, "Can't draw a circle with less than 3 vertices");
    assert(vertex_count <= 8192, "Can't draw a circle with absurd number of "
                             "vertices (more than 8192)");
}
body
{
    //this could be optimized by:
    //1:lookup tables (fixes function overhead)
    //2:line loop (fixes OpenGL call overhead)
    //3:single high-detail VBO for all circles (fixes OpenGL call overhead)
    //4:using a textured quad with a custom shader (fixes vertex count overhead)

    //The first vertex is right above center. 
    Vector2f line_start = center + Vector2f(radius, 0);
    Vector2f line_end; 
    //angle per vertex
    float vertex_angle = 2 * PI / vertex_count;
    //total angle of current vertex
    float angle = 0;
    for(uint vertex = 0; vertex < vertex_count; ++vertex)
    {
        angle += vertex_angle;
        line_end.x = center.x + radius * cos(angle); 
        line_end.y = center.y + radius * sin(angle); 
        VideoDriver.get.draw_line(line_start, line_end, color, color);
        line_start = line_end;
    }
}

void draw_rectangle(Vector2f min, Vector2f max,
                    Color color = Color(255, 255, 255, 255))
in
{
    assert(min.x <= max.x && min.y <= max.y, 
          "Can't draw a rectangle with min bounds greater than max");
}
body
{
    //this could be optimized by:
    //1:line loop (fixes OpenGL call overhead)
    //2:using a textured quad with a custom shader (fixes vertex count overhead)
    Vector2f max_min = Vector2f(max.x, min.y);
    Vector2f min_max = Vector2f(min.x, max.y);
    VideoDriver.get.draw_line(max, max_min, color, color);
    VideoDriver.get.draw_line(max_min, min, color, color);
    VideoDriver.get.draw_line(min, min_max, color, color);
    VideoDriver.get.draw_line(min_max, max, color, color);
}
