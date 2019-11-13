#!/usr/bin/env python3
#
# Run:
#   gunicorn -b 127.0.0.1:8000 example:api
#
# Or, if using pipenv:
#   pipenv run gunicorn -b 127.0.0.1:8000 example:api
#

from falcon import falcon

class QuoteResource:
    def on_get(self, req, resp):
        """Handles GET requests"""
        result = {
            'title': 'Default Response',
            'message': (
                "This is an example application "
                "using Python and Nginx reverse proxy."
            ),
            'author': 'Aris Ripandi <aris@ripandi.id>',
        }
        resp.media = result

def handle_404(req, resp):
    resp.status = falcon.HTTP_404
    # resp.body = 'Resource not found'
    resp.media = {
        'message': 'Resource not found',
        'documentation_url': 'https://github.com/riipandi/stackup'
    }

api = falcon.API()
api.add_route('/', QuoteResource())
api.add_sink(handle_404, '')
