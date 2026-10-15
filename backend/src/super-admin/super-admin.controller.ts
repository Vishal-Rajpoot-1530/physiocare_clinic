import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { IsEmail, IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { SuperAdminGuard } from './super-admin.guard';
import { SuperAdminService } from './super-admin.service';

class CreateUserDto {
  @IsString() @MinLength(1) @MaxLength(120) name!: string;
  @IsString() @MinLength(1) @MaxLength(40) phone!: string;
  @IsEmail() email!: string;
  @IsString() @MinLength(4) password!: string;
  @IsIn(['online','offline','ONLINE','OFFLINE']) type!: string;
}
class UpdateUserDto {
  @IsOptional() @IsString() @MinLength(1) @MaxLength(120) name?: string;
  @IsOptional() @IsString() @MinLength(1) @MaxLength(40) phone?: string;
  @IsOptional() @IsEmail() email?: string;
  @IsOptional() @IsIn(['online','offline','ONLINE','OFFLINE']) type?: string;
}
class ResetPasswordDto { @IsString() @MinLength(4) password!: string; }
class StatusDto { @IsIn(['active','temporarily_inactive','ACTIVE','TEMPORARILY_INACTIVE']) status!: string; }
class SubscriptionDto { @IsIn(['monthly','quarterly','yearly']) planType!: 'monthly'|'quarterly'|'yearly'; }

@UseGuards(SuperAdminGuard)
@Controller('super-admin/users')
export class SuperAdminController {
  constructor(private s: SuperAdminService) {}
  @Post() create(@Body() d: CreateUserDto) { return this.s.createUser(d); }
  @Get() users() { return this.s.users(); }
  @Patch(':id') update(@Param('id') id: string, @Body() d: UpdateUserDto) { return this.s.updateUser(id, d); }
  @Post(':id/reset-password') resetPassword(@Param('id') id: string, @Body() d: ResetPasswordDto) { return this.s.resetPassword(id, d.password); }
  @Patch(':id/status') status(@Param('id') id: string, @Body() d: StatusDto) { return this.s.setStatus(id, d.status); }
  @Post(':id/subscription') subscription(@Param('id') id: string, @Body() d: SubscriptionDto) { return this.s.assignOrRenew(id, d.planType); }
  @Post(':id/subscription/renew') renew(@Param('id') id: string, @Body() d: SubscriptionDto) { return this.s.assignOrRenew(id, d.planType); }
}
