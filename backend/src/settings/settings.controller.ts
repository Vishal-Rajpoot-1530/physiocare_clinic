import { Body, Controller, Get, Put, Req, UseGuards } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JwtGuard } from '../auth/jwt.guard';

@UseGuards(JwtGuard)
@Controller('settings')
export class SettingsController {
  constructor(private p: PrismaService) {}

  @Get()
  async get(@Req() r: any) {
    const [admin, plans] = await Promise.all([
      this.p.admin.findUniqueOrThrow({ where: { id: r.user.id } }),
      this.p.plan.findMany({
        where: { adminId: r.user.id },
        orderBy: [{ durationUnit: 'asc' }, { durationValue: 'asc' }],
      }),
    ]);
    return {
      revenue_goal: Number(admin.revenueGoal),
      plans: plans.map((plan) => ({
        duration_value: plan.durationValue,
        duration_unit: plan.durationUnit,
        fee: Number(plan.fee),
      })),
    };
  }

  @Put('goal')
  async goal(@Req() r: any, @Body() body: any) {
    await this.p.admin.update({
      where: { id: r.user.id },
      data: { revenueGoal: body.value },
    });
    return { success: true };
  }

  @Put('plans')
  async plans(@Req() r: any, @Body() body: any) {
    await this.p.$transaction(async (tx) => {
      await tx.plan.deleteMany({ where: { adminId: r.user.id } });
      if (body.plans?.length) {
        await tx.plan.createMany({
          data: body.plans.map((plan: any) => ({
            adminId: r.user.id,
            durationValue: Number(plan.duration_value),
            durationUnit: String(plan.duration_unit).toUpperCase(),
            fee: plan.fee,
          })),
        });
      }
    });
    return { success: true };
  }
}
