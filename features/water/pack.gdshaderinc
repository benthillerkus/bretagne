const float range = 3.0;

float pack(float v) {
  return (v / range) * 0.5 + 0.5;
}

float unpack(float v) {
  return (v - 0.5) * 2.0 * range;
}