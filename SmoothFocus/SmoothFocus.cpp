#include "Urho3DAll.h"
#include "SmoothFocus.h"

SmoothFocus::SmoothFocus(Context* context) : LogicComponent(context)
{
	SetUpdateEventMask(USE_POSTUPDATE);
}

void SmoothFocus::RegisterObject(Context* context)
{
	context->RegisterFactory<SmoothFocus>();
}

void SmoothFocus::Start()
{
	camera = GetNode()->GetComponent<Camera>();
	octree = GetScene()->GetComponent<Octree>();
	smoothTimeSec = 0.5f;
	smoothTimeElapsed = 0.001f;	
}

void SmoothFocus::PostUpdate(float timeStep)
{
	if (!vp | !rp) return;

	float targetFocus = GetNearestFocus(camera->GetFarClip());

	smoothFocus = Lerp(smoothFocus, targetFocus, timeStep * 10.0f / smoothTimeSec);
	rp->SetShaderParameter("SmoothFocus", Variant(smoothFocus));
}

void SmoothFocus::SetViewport(SharedPtr<Viewport> viewport)
{
	vp = SharedPtr<Viewport>(viewport);
	rp = SharedPtr<RenderPath>(vp->GetRenderPath());
	rp->SetShaderParameter("SmoothFocusEnabled", Variant(true));

}

float SmoothFocus::GetNearestFocus(float zCameraFarClip)
{
	if (!octree | !camera) return zCameraFarClip;
	
	PODVector<RayQueryResult> results;

	Ray ray = camera->GetScreenRay(0.5f, 0.5f);

	RayOctreeQuery query(results, ray, RAY_TRIANGLE, zCameraFarClip, DRAWABLE_GEOMETRY, -1);	
	octree->RaycastSingle(query);

	if (results.Size())
	{
		for (unsigned int i = 0; i < results.Size(); i++)
		{
			RayQueryResult& result = results[i];
			Vector3 hitPoint = result.position_;
			
			float distance = (camera->GetNode()->GetWorldPosition() - hitPoint).Length();
			
			return distance;
		}
	}

	return zCameraFarClip;
}

void SmoothFocus::SetFocusTime(float time)
{
	smoothTimeSec = time;
}

void SmoothFocus::SetSmoothFocusEnabled(bool enabled)
{
	rp->SetShaderParameter("SmoothFocusEnabled", Variant(enabled));
}

bool SmoothFocus::GetSmoothFocusEnabled()
{
	Variant v = rp->GetShaderParameter("SmoothFocusEnabled");	
	return v.GetBool();
}