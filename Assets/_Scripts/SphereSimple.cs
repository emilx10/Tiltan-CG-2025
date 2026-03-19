using UnityEngine;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct SphereSimple
{
	public Vector3 position;
	public float radius;
	public RayTracingMaterialSimple material;
}


