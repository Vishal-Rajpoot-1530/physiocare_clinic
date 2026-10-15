import { PrismaService } from '../prisma/prisma.service';
export declare class SettingsController {
    private p;
    constructor(p: PrismaService);
    get(r: any): Promise<{
        revenue_goal: number;
        plans: {
            duration_value: number;
            duration_unit: string;
            fee: number;
        }[];
    }>;
    goal(r: any, body: any): Promise<{
        success: boolean;
    }>;
    plans(r: any, body: any): Promise<{
        success: boolean;
    }>;
}
