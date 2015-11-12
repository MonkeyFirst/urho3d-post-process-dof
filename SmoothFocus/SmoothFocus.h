#pragma once
class SmoothFocus : public LogicComponent
{
	URHO3D_OBJECT(SmoothFocus, LogicComponent);
public:
	SmoothFocus(Context* context);
	static void RegisterObject(Context* context);
	virtual void Start();
	void PostUpdate(float timeStep);
	void SetViewport(SharedPtr<Viewport> viewport);
	void SetFocusTime(float time);
	void SetSmoothFocusEnabled(bool enabled);
	bool GetSmoothFocusEnabled();

	float smoothTimeElapsed;
	float smoothFocus;
	float smoothFocusRawLast;
	float smoothFocusRawPrev;
	float smoothTimeSec;

private:
	SharedPtr<Camera> camera;
	SharedPtr<RenderPath> rp;
	SharedPtr<Octree> octree;
	SharedPtr<Viewport> vp;

	// Get closer hit with scene drawables(from screen center), else return far value
	float GetNearestFocus(float zCameraFarClip);
	
};