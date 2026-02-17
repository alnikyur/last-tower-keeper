shader_type canvas_item;

uniform float yaw = 0.0;          // -1..1 (влево/вправо)
uniform float max_yaw = 0.55;     // сила поворота (рад)
uniform float persp = 0.45;       // перспектива (0..1)

void vertex() {
	// локальные координаты вершины
	vec2 p = VERTEX;

	// нормализуем X относительно ширины (приблизительно)
	// (работает хорошо для UI-элементов одинакового размера)
	float x = p.x;

	// "поворот" вокруг Y: появляется псевдо-Z = -x*sin
	float a = yaw * max_yaw;
	float c = cos(a);
	float s = sin(a);

	float x2 = x * c;      // сжатие по X
	float z  = -x * s;     // псевдо-глубина

	// перспектива: чем больше z, тем сильнее сдвиг
	float k = 1.0 / (1.0 + z * persp);

	VERTEX.x = x2 * k;
	VERTEX.y = p.y * k;
}
