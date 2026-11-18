# Recibe imágenes por POST en http://127.0.0.1:8799/<nombre> y las guarda en ~/Downloads
import http.server,os,re
D=os.path.expanduser('~/Downloads')
class H(http.server.BaseHTTPRequestHandler):
    def cors(self):
        self.send_header('Access-Control-Allow-Origin','*')
        self.send_header('Access-Control-Allow-Methods','POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers','*')
        self.send_header('Access-Control-Allow-Private-Network','true')
    def do_OPTIONS(self):
        self.send_response(204);self.cors();self.end_headers()
    def do_POST(self):
        n=re.sub(r'[^\w.-]','',self.path.strip('/')) or 'img.jpg'
        b=self.rfile.read(int(self.headers.get('Content-Length',0)))
        open(os.path.join(D,'Gemini_Generated_Image_'+n),'wb').write(b)
        self.send_response(200);self.cors();self.end_headers();self.wfile.write(b'ok')
    def log_message(self,*a): pass
http.server.HTTPServer(('127.0.0.1',8799),H).serve_forever()
