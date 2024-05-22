import React, { Component, ErrorInfo, ReactNode, useContext } from "react";
import { ErrorContext } from "./ErrorContext";

interface ErrorBoundaryProps {
  children: ReactNode;
}

class ErrorBoundary extends Component<ErrorBoundaryProps> {
  static contextType = ErrorContext;
  context!: React.ContextType<typeof ErrorContext>;

  public static getDerivedStateFromError(error: Error): null {
    return null;
  }

  public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error("Uncaught error:", error, errorInfo);
    if (this.context) {
      this.context.setError(error.message);
    }
  }

  public render() {
    if (this.context && this.context.hasError) {
      return <ErrorHandler error={this.context.message} />;
    }
    return this.props.children;
  }
}

interface ErrorHandlerProps {
  error: string | undefined;
}

function ErrorHandler({ error }: ErrorHandlerProps) {
  return (
    <div role="alert">
      <h2>Error</h2>
      <p style={{ color: 'red' }}>{error}</p>
    </div>
  );
}

export { ErrorBoundary, ErrorHandler };

