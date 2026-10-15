import { Module } from '@nestjs/common';
import { SuperAdminController } from './super-admin.controller';
import { SuperAdminGuard } from './super-admin.guard';
import { SuperAdminService } from './super-admin.service';
@Module({ controllers: [SuperAdminController], providers: [SuperAdminService, SuperAdminGuard] })
export class SuperAdminModule {}
