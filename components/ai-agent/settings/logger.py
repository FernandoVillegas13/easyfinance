import sys
from loguru import logger

logger.remove()

logger.add(
    sys.stdout,
    level="INFO",
    format=(
        "<green>{time:YYYY-MM-DD HH:mm:ss}</green> | "
        "<level>{level: <8}</level> | "
        "<cyan>{name}</cyan>:<cyan>{function}</cyan> | "
        "{message}"
    ),
    colorize=True,
    backtrace=True,
    diagnose=False,
)
