using UnityEngine;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
[System.Serializable]
public struct RayTracingMaterialSimple
{
	public Color colour;

	public void SetDefaultValues()
	{
		colour = Color.white;
	}
}


