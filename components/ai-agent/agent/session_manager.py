from strands.session.s3_session_manager import S3SessionManager
from settings.general import settings

class SessionManager:

    def get_session_manager(self, session_id):
        # S3-based persistence
        session_manager = S3SessionManager(
            session_id=str(session_id),
            bucket=settings.bucket_session,
            prefix=settings.bucket_prefix,
        )

        return session_manager