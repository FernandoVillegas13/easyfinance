from strands.session.s3_session_manager import S3SessionManager
from settings.general import settings
import boto3

class SessionManager:
    def __init__(self):
        self.boto_session = boto3.Session(region_name=settings.region_name)

    def get_session_manager(self, session_id):
        # S3-based persistence
        session_manager = S3SessionManager(
            session_id=session_id,
            boto_session=self.boto_session,
            bucket=settings.bucket_session,
            prefix=settings.bucket_prefix,
        )

        return session_manager