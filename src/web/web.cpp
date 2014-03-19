/*
    TE4 - T-Engine 4
    Copyright (C) 2009, 2010, 2011, 2012, 2013 Nicolas Casalini

    No permission to copy or replicate in any ways, awesomium is not gpl so we cant link directly
*/

extern "C" {
#include <stdio.h>
#include <stdlib.h>
#include "web-external.h"
}
#include "web.h"
#include "web-internal.h"

#include <Awesomium/WebCore.h>
#include <Awesomium/BitmapSurface.h>
#include <Awesomium/DataSource.h>
#include <Awesomium/STLHelpers.h>
#include "gl_texture_surface.h"

void *(*web_mutex_create)();
void (*web_mutex_destroy)(void *mutex);
void (*web_mutex_lock)(void *mutex);
void (*web_mutex_unlock)(void *mutex);
unsigned int (*web_make_texture)(int w, int h);
void (*web_del_texture)(unsigned int tex);
void (*web_texture_update)(unsigned int tex, int w, int h, const void* buffer);
static void (*web_key_mods)(bool *shift, bool *ctrl, bool *alt, bool *meta);

using namespace Awesomium;

class PhysfsDataSource;
class WebJShandler;

static WebCore *web_core = NULL;
static WebSession *web_session = NULL;
static PhysfsDataSource *web_data_source = NULL;

typedef struct {
	WebJShandler *listener;
	int methods_ref;
} web_js_type;

class WebListener;

static char *webstring_to_buf(const WebString &wstr, size_t *flen) {
	char *buf;
	unsigned int len = 0;
	len = wstr.ToUTF8(NULL, 0);
	buf = (char*)malloc(len + 1);
	wstr.ToUTF8(buf, len);	
	buf[len] = '\0';
	if (flen) *flen = (size_t)len;
	return buf;
}

class WebJShandler : public JSMethodHandler {
public:
	web_js_type *js;
	virtual void OnMethodCall(WebView* caller, unsigned int remote_object_id, const WebString& method_name, const JSArray& args) {
	}

	virtual JSValue OnMethodCallWithReturnValue(WebView* caller, unsigned int remote_object_id, const WebString& method_name, const JSArray& args) {
	}
};

class WebListener : 
	public WebViewListener::View,
	public WebViewListener::Download,
	public WebViewListener::Load
{
private:
	int handlers;
public:
	WebListener(int handlers) { this->handlers = handlers; }

	virtual void OnChangeTitle(Awesomium::WebView* caller, const Awesomium::WebString& title) {
		char *cur_title = webstring_to_buf(title, NULL);
		WebEvent *event = new WebEvent();
		event->kind = TE4_WEB_EVENT_TITLE_CHANGE;
		event->handlers = handlers;
		event->data.title = cur_title;
		push_event(event);
	}

	virtual void OnChangeAddressBar(Awesomium::WebView* caller, const Awesomium::WebURL& url) {
	}

	virtual void OnChangeTooltip(Awesomium::WebView* caller, const Awesomium::WebString& tooltip) {
	}

	virtual void OnChangeTargetURL(Awesomium::WebView* caller, const Awesomium::WebURL& url) {
	}

	virtual void OnChangeCursor(Awesomium::WebView* caller, Awesomium::Cursor cursor) {
	}

	virtual void OnChangeFocus(Awesomium::WebView* caller, Awesomium::FocusedElementType focused_type) {
	}

	virtual void OnAddConsoleMessage(Awesomium::WebView* caller, const Awesomium::WebString& message, int line_number, const Awesomium::WebString& source) {
	}

	virtual void OnShowCreatedWebView(Awesomium::WebView* caller, Awesomium::WebView* new_view, const Awesomium::WebURL& opener_url, const Awesomium::WebURL& target_url, const Awesomium::Rect& initial_pos, bool is_popup) {
		new_view->Destroy();

		WebString rurl = target_url.spec();
		char *url = webstring_to_buf(rurl, NULL);

		WebEvent *event = new WebEvent();
		event->kind = TE4_WEB_EVENT_REQUEST_POPUP_URL;
		event->handlers = handlers;
		event->data.popup.url = url;
		event->data.popup.w = initial_pos.width;
		event->data.popup.h = initial_pos.height;
		push_event(event);

		printf("[WEB] stopped popup to %s (%dx%d), pushing event...\n", url, event->data.popup.w, event->data.popup.h);
	}

	void OnRequestDownload(WebView* caller, int download_id, const WebURL& wurl, const WebString& suggested_filename, const WebString& mime_type) {
		WebString rurl = wurl.spec();
		const char *mime = webstring_to_buf(mime_type, NULL);
		const char *url = webstring_to_buf(rurl, NULL);
		const char *name = webstring_to_buf(suggested_filename, NULL);
		printf("[WEB] Download request [name: %s] [mime: %s] [url: %s]\n", name, mime, url);

		WebEvent *event = new WebEvent();
		event->kind = TE4_WEB_EVENT_DOWNLOAD_REQUEST;
		event->handlers = handlers;
		event->data.download_request.url = url;
		event->data.download_request.name = name;
		event->data.download_request.mime = mime;
		event->data.download_request.id = download_id;
		push_event(event);
	}
	void OnUpdateDownload(WebView* caller, int download_id, int64 total_bytes, int64 received_bytes, int64 current_speed) {
		WebEvent *event = new WebEvent();
		event->kind = TE4_WEB_EVENT_DOWNLOAD_UPDATE;
		event->handlers = handlers;
		event->data.download_update.id = download_id;
		event->data.download_update.got = received_bytes;
		event->data.download_update.total = total_bytes;
		event->data.download_update.percent = 100 * ((double)received_bytes / (double)total_bytes);
		event->data.download_update.speed = current_speed;
		push_event(event);
	}
	void OnFinishDownload(WebView* caller, int download_id, const WebURL& url, const WebString& saved_path) {
		WebEvent *event = new WebEvent();
		event->kind = TE4_WEB_EVENT_DOWNLOAD_FINISH;
		event->handlers = handlers;
		event->data.download_finish.id = download_id;
		push_event(event);
	}

	/// This event occurs when the page begins loading a frame.
	virtual void OnBeginLoadingFrame(Awesomium::WebView* caller, int64 frame_id, bool is_main_frame, const Awesomium::WebURL& wurl, bool is_error_page) {
		WebString rurl = wurl.spec();
		const char *url = webstring_to_buf(rurl, NULL);

		WebEvent *event = new WebEvent();
		event->kind = TE4_WEB_EVENT_LOADING;
		event->handlers = handlers;
		event->data.loading.url = url;
		event->data.loading.status = 0;
		push_event(event);
	}

	/// This event occurs when a frame fails to load. See error_desc
	/// for additional information.
	virtual void OnFailLoadingFrame(Awesomium::WebView* caller, int64 frame_id, bool is_main_frame, const Awesomium::WebURL& wurl, int error_code, const Awesomium::WebString& error_desc) {
		WebString rurl = wurl.spec();
		const char *url = webstring_to_buf(rurl, NULL);

		WebEvent *event = new WebEvent();
		event->kind = TE4_WEB_EVENT_LOADING;
		event->handlers = handlers;
		event->data.loading.url = url;
		event->data.loading.status = -1;
		push_event(event);
	}

	/// This event occurs when the page finishes loading a frame.
	/// The main frame always finishes loading last for a given page load.
	virtual void OnFinishLoadingFrame(Awesomium::WebView* caller, int64 frame_id, bool is_main_frame, const Awesomium::WebURL& wurl) {

	}

	/// This event occurs when the DOM has finished parsing and the
	/// window object is available for JavaScript execution.
	virtual void OnDocumentReady(Awesomium::WebView* caller, const Awesomium::WebURL& wurl) {
		WebString rurl = wurl.spec();
		const char *url = webstring_to_buf(rurl, NULL);

		WebEvent *event = new WebEvent();
		event->kind = TE4_WEB_EVENT_LOADING;
		event->handlers = handlers;
		event->data.loading.url = url;
		event->data.loading.status = 1;
		push_event(event);
	}
};

class PhysfsDataSource : public DataSource {
public:
	virtual void OnRequest(int request_id, const WebString& path) {
	}
};


class WebViewOpaque {
public:
	WebView *view;
	WebListener *listener;
	JSObject *te4core;
	web_js_type *js;
};

void te4_web_new(web_view_type *view, const char *url, int w, int h) {
	size_t urllen = strlen(url);
	
	WebViewOpaque *opaque = new WebViewOpaque();
	view->opaque = (void*)opaque;

	opaque->view = web_core->CreateWebView(w, h, web_session, kWebViewType_Offscreen);
	opaque->listener = new WebListener(view->handlers);
	opaque->view->set_view_listener(opaque->listener);
	opaque->view->set_download_listener(opaque->listener);
	opaque->view->set_load_listener(opaque->listener);
	opaque->te4core = NULL;
	opaque->js = NULL;
	view->w = w;
	view->h = h;
	view->closed = false;

	WebURL lurl(WebString::CreateFromUTF8(url, urllen));
	opaque->view->LoadURL(lurl);
	opaque->view->SetTransparent(true);
	printf("Created webview: %s\n", url);
}

bool te4_web_close(web_view_type *view) {
	WebViewOpaque *opaque = (WebViewOpaque*)view->opaque;
	if (!view->closed) {
		opaque->view->Destroy();
		delete opaque->listener;
		view->closed = true;
		if (opaque->js) {
			delete opaque->js->listener;
			free(opaque->js);
		}
		if (opaque->te4core) delete opaque->te4core;
		printf("Destroyed webview\n");
		return true;
	}
	return false;
}

bool te4_web_toscreen(web_view_type *view, int *w, int *h, unsigned int *tex) {
	WebViewOpaque *opaque = (WebViewOpaque*)view->opaque;
	if (view->closed) return false;

	const GLTextureSurface* surface = static_cast<const GLTextureSurface*> (opaque->view->surface());
	if (!surface) return false;
	unsigned int t = surface->GetTexture();

	*tex = t;
	*w = (*w < 0) ? view->w : *w;
	*h = (*h < 0) ? view->h : *h;
	return true;
}

bool te4_web_loading(web_view_type *view) {
	WebViewOpaque *opaque = (WebViewOpaque*)view->opaque;
	if (view->closed) return false;
	return opaque->view->IsLoading();
}

void te4_web_focus(web_view_type *view, bool focus) {
	WebViewOpaque *opaque = (WebViewOpaque*)view->opaque;
	if (view->closed) return;

	if (focus) opaque->view->Focus();
	else opaque->view->Unfocus();
}

void te4_web_inject_mouse_move(web_view_type *view, int x, int y) {
	WebViewOpaque *opaque = (WebViewOpaque*)view->opaque;
	if (view->closed) return;

	opaque->view->InjectMouseMove(x, y);
}

void te4_web_inject_mouse_wheel(web_view_type *view, int x, int y) {
	WebViewOpaque *opaque = (WebViewOpaque*)view->opaque;
	if (view->closed) return;

	opaque->view->InjectMouseWheel(-y, -x);
}

void te4_web_inject_mouse_button(web_view_type *view, int kind, bool up) {
	WebViewOpaque *opaque = (WebViewOpaque*)view->opaque;
	if (view->closed) return;

	MouseButton b = kMouseButton_Left;
	if (kind == 2) b = kMouseButton_Middle;
	else if (kind == 3) b = kMouseButton_Right;

	if (up) opaque->view->InjectMouseUp(b);
	else opaque->view->InjectMouseDown(b);
}

void te4_web_inject_key(web_view_type *view, int scancode, int asymb, const char *uni, int unilen, bool up) {
	WebViewOpaque *opaque = (WebViewOpaque*)view->opaque;
	if (view->closed) return;

	WebKeyboardEvent keyEvent;
	keyEvent.type = !up ? WebKeyboardEvent::kTypeKeyDown : WebKeyboardEvent::kTypeKeyUp;
	
	char buf[20];
	keyEvent.virtual_key_code = asymb;
	GetKeyIdentifierFromVirtualKeyCode(keyEvent.virtual_key_code, (char**)&buf);
	strcpy(keyEvent.key_identifier, buf);
	
	bool shift, ctrl, alt, meta;
	web_key_mods(&shift, &ctrl, &alt, &meta);
	keyEvent.modifiers = 0;
	if (shift) keyEvent.modifiers |= WebKeyboardEvent::kModShiftKey;
	else if (ctrl) keyEvent.modifiers |= WebKeyboardEvent::kModControlKey;
	else if (alt) keyEvent.modifiers |= WebKeyboardEvent::kModAltKey;
	else if (meta) keyEvent.modifiers |= WebKeyboardEvent::kModMetaKey;
	
	keyEvent.native_key_code = scancode;
	
	if (up) {
		opaque->view->InjectKeyboardEvent(keyEvent);
	} else {
		if (uni) {
			WebString wstr = WebString::CreateFromUTF8(uni, unilen);
			memcpy(keyEvent.text, wstr.data(), wstr.length() * sizeof(wchar16));
			memcpy(keyEvent.unmodified_text, wstr.data(), wstr.length() * sizeof(wchar16));
		}
		
		opaque->view->InjectKeyboardEvent(keyEvent);

		if (uni) {
			keyEvent.type = WebKeyboardEvent::kTypeChar;
			keyEvent.virtual_key_code = keyEvent.text[0];
			keyEvent.native_key_code = keyEvent.text[0];
			opaque->view->InjectKeyboardEvent(keyEvent);
		}
	}
}

void te4_web_download_action(web_view_type *view, long id, const char *path) {
	WebViewOpaque *opaque = (WebViewOpaque*)view->opaque;
	if (view->closed) return;

	if (path) {
		WebString wpath = WebString::CreateFromUTF8(path, strlen(path));
		opaque->view->DidChooseDownloadPath(id, wpath);
	} else {
		opaque->view->DidCancelDownload(id);
	}
}

void te4_web_do_update(void (*cb)(WebEvent*)) {
	if (!web_core) return;

	web_core->Update();
	WebEvent *event;
	while (event = pop_event()) {
		cb(event);

		switch (event->kind) {
			case TE4_WEB_EVENT_TITLE_CHANGE:
				free((void*)event->data.title);
				break;
			case TE4_WEB_EVENT_REQUEST_POPUP_URL:
				free((void*)event->data.popup.url);
				break;
			case TE4_WEB_EVENT_DOWNLOAD_REQUEST:
				free((void*)event->data.download_request.url);
				free((void*)event->data.download_request.name);
				free((void*)event->data.download_request.mime);
				break;
			case TE4_WEB_EVENT_LOADING:
				free((void*)event->data.loading.url);
				break;
		}

		delete event;
	}
}

void te4_web_setup(
	int argc, char **gargv, char *spawnc,
	void*(*mutex_create)(), void(*mutex_destroy)(void*), void(*mutex_lock)(void*), void(*mutex_unlock)(void*),
	unsigned int (*make_texture)(int, int), void (*del_texture)(unsigned int), void (*texture_update)(unsigned int, int, int, const void*),
	void (*key_mods)(bool*, bool*, bool*, bool*)
	) {

	web_mutex_create = mutex_create;
	web_mutex_destroy = mutex_destroy;
	web_mutex_lock = mutex_lock;
	web_mutex_unlock = mutex_unlock;
	web_make_texture = make_texture;
	web_del_texture = del_texture;
	web_texture_update = texture_update;
	web_key_mods = key_mods;
	if (!web_core) {
		web_core = WebCore::Initialize(WebConfig());
		web_core->set_surface_factory(new GLTextureSurfaceFactory());
		web_session = web_core->CreateWebSession(WSLit(""), WebPreferences());
		web_data_source = new PhysfsDataSource();
		web_session->AddDataSource(WSLit("te4"), web_data_source);
	}
}

void te4_web_initialize() {
	te4_web_init_utils();
}
