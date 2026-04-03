from django.conf import settings
from django.contrib import admin
from django.db import DatabaseError, connection
from django.http import JsonResponse
from django.urls import include, path, re_path
from django.views.static import serve


REQUIRED_TABLES = {
    "accounts_user",
    "token_blacklist_blacklistedtoken",
    "token_blacklist_outstandingtoken",
}


def health_check(_request):
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")

        existing_tables = set(connection.introspection.table_names())
        missing_tables = sorted(REQUIRED_TABLES - existing_tables)
        if missing_tables:
            return JsonResponse(
                {
                    "status": "degraded",
                    "database": "ok",
                    "migrations": "pending",
                    "missing_tables": missing_tables,
                },
                status=503,
            )

        return JsonResponse({"status": "ok", "database": "ok"})
    except DatabaseError:
        return JsonResponse(
            {
                "status": "degraded",
                "database": "error",
                "detail": "Database not reachable",
            },
            status=503,
        )


urlpatterns = [
    path("admin/", admin.site.urls),
    path("health/", health_check, name="health"),
    path("api/v1/", include("apps.accounts.urls")),
]

if settings.DEBUG or settings.SERVE_MEDIA_FILES:
    media_prefix = settings.MEDIA_URL.lstrip("/")
    urlpatterns += [
        re_path(
            rf"^{media_prefix}(?P<path>.*)$",
            serve,
            {"document_root": settings.MEDIA_ROOT},
        )
    ]
