from django.core.management.base import BaseCommand
from django.core.files.storage import default_storage
from django.conf import settings
import os
from pathlib import Path

class Command(BaseCommand):
    help = 'Migrate existing media files from local storage to S3'

    def add_arguments(self, parser):
        parser.add_argument(
            '--delete-local',
            action='store_true',
            help='Delete local files after successful upload to S3',
        )

    def handle(self, *args, **options):
        media_root = Path(settings.MEDIA_ROOT)
        delete_local = options['delete_local']
        
        if not media_root.exists():
            self.stdout.write(
                self.style.WARNING(f'Media root {media_root} does not exist. Nothing to migrate.')
            )
            return

        self.stdout.write(f'Starting migration of media files from {media_root} to S3...')
        
        migrated_count = 0
        error_count = 0
        
        # Walk through all files in media directory
        for root, dirs, files in os.walk(media_root):
            for file in files:
                file_path = Path(root) / file
                relative_path = file_path.relative_to(media_root)
                
                try:
                    # Read the file
                    with open(file_path, 'rb') as f:
                        # Upload to S3
                        s3_path = default_storage.save(str(relative_path), f)
                        
                        # Verify upload
                        if default_storage.exists(s3_path):
                            migrated_count += 1
                            self.stdout.write(
                                self.style.SUCCESS(f'✓ Migrated: {relative_path} -> {s3_path}')
                            )
                            
                            # Delete local file if requested
                            if delete_local:
                                os.remove(file_path)
                                self.stdout.write(f'  Deleted local file: {file_path}')
                        else:
                            error_count += 1
                            self.stdout.write(
                                self.style.ERROR(f'✗ Failed to verify upload: {relative_path}')
                            )
                            
                except Exception as e:
                    error_count += 1
                    self.stdout.write(
                        self.style.ERROR(f'✗ Error migrating {relative_path}: {str(e)}')
                    )

        self.stdout.write('\n' + '='*50)
        self.stdout.write(
            self.style.SUCCESS(f'Migration completed!')
        )
        self.stdout.write(f'Successfully migrated: {migrated_count} files')
        if error_count > 0:
            self.stdout.write(
                self.style.WARNING(f'Errors: {error_count} files')
            )
        
        if delete_local:
            self.stdout.write(
                self.style.SUCCESS('Local files have been deleted after successful migration.')
            )
        else:
            self.stdout.write(
                self.style.WARNING('Local files were preserved. Use --delete-local to remove them.')
            ) 