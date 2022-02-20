#define PI  3.14159265359
#define PI2 6.28318530718
#define TAU 6.28318530718
#define E   2.71828182846
#define ASPECT_RATIO (-UNITY_MATRIX_P[0][0]/UNITY_MATRIX_P[1][1])

float curve(float src, float factor) {
    return src - (src - src * src) * -factor;
}
float2 curve(float2 src, float factor) {
    return src - (src - src * src) * -factor;
}
float3 curve(float3 src, float factor) {
    return src - (src - src * src) * -factor;
}
float4 curve(float4 src, float factor) {
    return src - (src - src * src) * -factor;
}

float pow2(float src) {
    return src * src;
}

float pow3(float src) {
    return src * src;
}

float remap01(float x, float min, float max)
{
    return (x - min) / (max - min);
}

float clampedRemap01(float x, float min, float max)
{
    if (min == max) {
        step(x, min);
    }
    return saturate((x - min) / (max - min));
}

float remap(float value, float inputMin, float inputMax, float outputMin, float outputMax)
{
    return (value - inputMin) * ((outputMax - outputMin) / (inputMax - inputMin)) + outputMin;
}

float linearstep(float a, float b, float x)
{
    return saturate((x - a) / (b - a));
}

float smoothstep01(float a, float b, float x)
{
  float t = saturate((x - a)/(b - a));
  return t * t * (3.0 - (2.0 * t));
}

float rand(float2 co){
    return frac(sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453);
}

float sigmoid(float x, float a) {
    return 1 / (1 + pow(E, -a * x));
}