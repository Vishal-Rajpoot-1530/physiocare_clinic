import { PrismaService } from '../prisma/prisma.service';
export declare class FinanceController {
    private p;
    constructor(p: PrismaService);
    all(r: any, m?: string): Promise<{
        id: number;
        admin_id: number;
        member_id: number | null;
        member_name: string;
        amount: number;
        type: string;
        plan: string;
        description: string;
        paid_at: string;
        method: string;
    }[]>;
}
