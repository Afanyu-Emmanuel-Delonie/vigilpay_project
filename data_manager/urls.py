# data_manager/urls.py

from django.urls import path

from .views import UploadDataView

urlpatterns = [
    # POST a CSV file under the key "file" to this endpoint.  No page rendering
    # is performed; a JSON response is returned.
    path('upload/', UploadDataView.as_view(), name='upload-data'),
]

"""
Note: Remember to include data_manager.urls in your project’s root urls.py if not already done:
path('data-manager/', include('data_manager.urls')),
"""