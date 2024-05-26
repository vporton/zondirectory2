import React, { Component, ErrorInfo, ReactNode, useContext } from "react";
import { ErrorContext } from "./ErrorContext";
import { Link } from "react-router-dom";
import { Button } from "react-bootstrap";

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
  const { resetError } = useContext(ErrorContext)!;
  return (
    <div role="alert">
      <h2>Error</h2>
      <p style={{ color: 'red' }}>{error?.toString()}</p>
      <p><Button onClick={resetError}>Return back.</Button></p>
    </div>
  );
}

export { ErrorBoundary, ErrorHandler };
