#pragma once
class SmoothFocus : public LogicComponent
{
	URHO3D_OBJECT(SmoothFocus, LogicComponent);
public:
	SmoothFocus(Context* context);
	static void RegisterObject(Context* context);
	virtual void Start();
	void Update(float timeStep);
	void FixedUpdate(float timeStep);
	
	/// Set viewport for RenderPath shader param update
	void SetViewport(SharedPtr<Viewport> viewport);
	
	/// How long camera will be do focusing (default is 0.5f sec)
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