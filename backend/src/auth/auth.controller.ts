import { Body, Controller, Get, Patch, Post, Put, Req, UseGuards } from '@nestjs/common';
import { IsEmail, IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { JwtGuard } from './jwt.guard';
import { AuthService } from './auth.service';

class RegisterDto {
  @IsString() @MinLength(1) @MaxLength(120) name!: string;
  @IsEmail() email!: string;
  @IsOptional() @IsString() @MaxLength(40) phone?: string;
  @IsOptional() @IsIn(['ONLINE', 'OFFLINE', 'online', 'offline']) type?: string;
  @IsString() @MinLength(4) password!: string;
}

class LoginDto {
  @IsEmail() email!: string;
  @IsString() password!: string;
}

class UpdateProfileDto {
  @IsString() @MinLength(1) @MaxLength(120) name!: string;
}

class ChangePasswordDto {
  @IsString() currentPassword!: string;
  @IsString() @MinLength(4) newPassword!: string;
}

@Controller('auth')
export class AuthController {
  constructor(private s: AuthService) {}

  @Post('register')
  register(@Body() d: RegisterDto) {
    return this.s.register(d);
  }

  @Post('login')
  login(@Body() d: LoginDto) {
    return this.s.login(d);
  }

  @UseGuards(JwtGuard)
  @Get('profile')
  profile(@Req() r: any) {
    return this.s.getProfile(r.user.id);
  }

  @UseGuards(JwtGuard)
  @Patch('profile')
  updateProfile(@Req() r: any, @Body() d: UpdateProfileDto) {
    return this.s.updateProfile(r.user.id, d.name);
  }

  @UseGuards(JwtGuard)
  @Put('password')
  changePassword(@Req() r: any, @Body() d: ChangePasswordDto) {
    return this.s.changePassword(r.user.id, d.currentPassword, d.newPassword);
  }
}