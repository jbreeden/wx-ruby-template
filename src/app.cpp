#include <functional>
#include <chrono>
#include "wx/wx.h"
#include "wx/app.h"
#include "wx/xrc/xmlres.h"
#include "mainFrame.h"

#define RUBYDO_NO_CONFLICTS
#include "rubydo.h"
#undef RUBYDO_NO_CONFLICTS

using namespace std;

class App : public wxApp
{
public:
  virtual bool OnInit() {
    wxApp::OnInit();
    wxXmlResource::Get()->InitAllHandlers();
    wxXmlResource::Get()->Load("app.xrc");
    MainFrame *frame = new MainFrame();
    wxXmlResource::Get()->LoadFrame(frame, NULL, "main_frame");
    frame->Show();
    return true;
  }
};

int main(int argc, char** argv) {
  ruby::init(argc, argv);

  ruby::without_gvl(DO [&](){
    wxApp::SetInstance(new App);
    wxEntryStart(argc, argv);
    wxTheApp->OnInit();
    wxTheApp->OnRun();
    wxTheApp->OnExit();
    wxEntryCleanup();
  } END, DO [&](){
    cerr << "UBF callback hit (ruby execution has completed)" << endl;
  } END);

  return 0;
}
