import { PrismaService } from './prisma/prisma.service';
export declare class HealthController {
    private p;
    constructor(p: PrismaService);
    health(): Promise<{
        success: boolean;
        message: string;
    }>;
}
