using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent (typeof(Camera))]
public class OceanFog : MonoBehaviour {
    Material fogMaterial = null;
	public Shader fogShader = null;
	
	public Vector3 startFade = Vector3.zero;
	public Vector3 endFade = new Vector3(5, 120, 250);
	public float surfaceHeight = 5.0f;
	public float visibility = 80.0f;
    public MeshRenderer waterPlane;
	
	void Awake ()
	{
		if (fogShader != null) 
			fogMaterial = new Material(fogShader);
		GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;

        waterPlane.transform.position = new Vector3(0, surfaceHeight-0.01f, 0);
        waterPlane.transform.rotation = Quaternion.Euler(180, 0, 0);
	}

	[ImageEffectOpaque]
	void OnRenderImage(RenderTexture src, RenderTexture dest) {
		if (fogShader != null && fogMaterial != null) {
            waterPlane.transform.position = new Vector3(0, surfaceHeight-0.01f, 0);
            waterPlane.transform.rotation = Quaternion.Euler(180, 0, 0);

            Camera cam = GetComponent<Camera>();
			Transform camtr = cam.transform;
			float camNear = cam.nearClipPlane;
			float camFar = cam.farClipPlane;
			float camFov = cam.fieldOfView;
			float camAspect = cam.aspect;

            Matrix4x4 frustumCorners = Matrix4x4.identity;

			float fovWHalf = camFov * 0.5f;

			Vector3 toRight = camtr.right * camNear * Mathf.Tan (fovWHalf * Mathf.Deg2Rad) * camAspect;
			Vector3 toTop = camtr.up * camNear * Mathf.Tan (fovWHalf * Mathf.Deg2Rad);

			Vector3 topLeft = (camtr.forward * camNear - toRight + toTop);
			float camScale = topLeft.magnitude * camFar/camNear;

            topLeft.Normalize();
			topLeft *= camScale;

			Vector3 topRight = (camtr.forward * camNear + toRight + toTop);
            topRight.Normalize();
			topRight *= camScale;

			Vector3 bottomRight = (camtr.forward * camNear + toRight - toTop);
            bottomRight.Normalize();
			bottomRight *= camScale;

			Vector3 bottomLeft = (camtr.forward * camNear - toRight - toTop);
            bottomLeft.Normalize();
			bottomLeft *= camScale;

            frustumCorners.SetRow (0, topLeft);
            frustumCorners.SetRow (1, topRight);
            frustumCorners.SetRow (2, bottomRight);
            frustumCorners.SetRow (3, bottomLeft);

			var camPos= camtr.position;
            fogMaterial.SetMatrix ("_FrustumCornersWS", frustumCorners);
            fogMaterial.SetVector ("_CameraWS", camPos);

			Matrix4x4 viewMat = cam.worldToCameraMatrix;
			Matrix4x4 projMat = GL.GetGPUProjectionMatrix( cam.projectionMatrix, false );
			Matrix4x4 viewProjMat = (projMat * viewMat);          
			Shader.SetGlobalMatrix("_ViewProjInv", viewProjMat.inverse);

			fogMaterial.SetVector("_StartFade", startFade);
			fogMaterial.SetVector("_EndFade", endFade);
			fogMaterial.SetFloat("_SurfaceHeight", surfaceHeight);
			fogMaterial.SetFloat("_Visibility", visibility);
			fogMaterial.SetColor("_CameraBGColor", GetComponent<Camera>().backgroundColor);
			//Graphics.Blit(src, dest, fogMaterial);

			CustomGraphicsBlit (src, dest, fogMaterial, 0);
		}
    }

	static void CustomGraphicsBlit (RenderTexture source, RenderTexture dest, Material fxMaterial, int passNr)
		{
            RenderTexture.active = dest;

            fxMaterial.SetTexture ("_MainTex", source);

            GL.PushMatrix ();
            GL.LoadOrtho ();

            fxMaterial.SetPass (passNr);

            GL.Begin (GL.QUADS);

            GL.MultiTexCoord2 (0, 0.0f, 0.0f);
            GL.Vertex3 (0.0f, 0.0f, 3.0f); // BL

            GL.MultiTexCoord2 (0, 1.0f, 0.0f);
            GL.Vertex3 (1.0f, 0.0f, 2.0f); // BR

            GL.MultiTexCoord2 (0, 1.0f, 1.0f);
            GL.Vertex3 (1.0f, 1.0f, 1.0f); // TR

            GL.MultiTexCoord2 (0, 0.0f, 1.0f);
            GL.Vertex3 (0.0f, 1.0f, 0.0f); // TL

            GL.End ();
            GL.PopMatrix ();
        }
}
