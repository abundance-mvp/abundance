export interface LogContext {
  itemId: string;
  userId?: string;
  layer?: '1' | '2a' | '2b' | '3';
  operation?: string;
  [key: string]: any;
}

export class StructuredLogger {
  private context: LogContext;

  constructor(context: LogContext) {
    this.context = context;
  }

  info(message: string, data?: Record<string, any>): void {
    console.log(JSON.stringify({
      severity: 'INFO',
      message,
      ...this.context,
      ...data,
      timestamp: new Date().toISOString(),
    }));
  }

  warn(message: string, data?: Record<string, any>): void {
    console.warn(JSON.stringify({
      severity: 'WARNING',
      message,
      ...this.context,
      ...data,
      timestamp: new Date().toISOString(),
    }));
  }

  error(message: string, error: Error | unknown, data?: Record<string, any>): void {
    const errorData = error instanceof Error
      ? { errorMessage: error.message, errorStack: error.stack }
      : { error: String(error) };

    console.error(JSON.stringify({
      severity: 'ERROR',
      message,
      ...this.context,
      ...errorData,
      ...data,
      timestamp: new Date().toISOString(),
    }));
  }

  withContext(additionalContext: Record<string, any>): StructuredLogger {
    return new StructuredLogger({
      ...this.context,
      ...additionalContext,
    });
  }
}
